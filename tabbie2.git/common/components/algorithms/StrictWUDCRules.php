<?php

namespace common\components\algorithms;

use common\components\TabAlgorithm;
use common\models\Adjudicator;
use common\models\DrawLine;
use common\models\EnergyConfig;
use common\models\Round;
use common\models\Team;
use common\models\Venue;
use Yii;
use yii\base\Exception;

class StrictWUDCRules extends TabAlgorithm {

	/**
	 * Function to calculate a draw based on WUDC strict Rules


*
*@param Venue[]        $venues
	 * @param Team[]         $teams
	 * @param Adjudicators[] $adjudicators
	 * @param type           $preset_panels
	 *
	 * @return type
	 * @throws Exception
	 */
	public function makeDraw($venues, $teams, $adjudicators, $preset_panels = array()) {

		Yii::beginProfile("generateDraw");
		$memory_limit = (ini_get('memory_limit') * 1024 * 1024) * 0.9;

		$active_rooms = (count($teams) / 4);
		if (count($teams) % 4 != 0)
			throw new Exception("Amount of active Teams must be divided by 4 ;) - (active: " . count($teams) . ")", "500");
		if ($active_rooms > count($venues))
			throw new Exception("Not enough active Rooms (active:" . count($venues) . " required:" . $active_rooms . ")", "500");
		if ($active_rooms > count($adjudicators))
			throw new Exception("Not enough adjudicators (active:" . count($adjudicators) . " min-required:" . $active_rooms . ")", "500");

		/**
		 * Shuffle venues
		 */
		shuffle($venues);

		/**
		 * Sort Adjudicator at Strength
		 */
		$adjudicators = $this->sort_adjudicators($adjudicators);
		/*
		  First we need to make the brackets for each debate. This means ordering the teams by the number of points.
		 */
		$teams = $this->sort_teams($teams);

		/*
		  Then, within point brackets, we randomise the teams
		 */
		$teams = $this->randomise_within_points($teams);

		/**
		 * Set Past Position Matrix
		 */
		for ($i = 0; $i < count($teams); $i++) {
			$teams[$i]["positionMatrix"] = Team::getPastPositionMatrix($teams[$i]["id"], $this->tournament_id);
		}

		/**
		 * Generate a first rough draw by running the teams down from top to bottom and allocate them
		 */
		for ($i = 0; $i < $active_rooms; $i++) {
			$line = new DrawLine();

			$line->id = $i;
			$choosen = array_splice($teams, 0, 4);
			shuffle($choosen);
			$line->setTeamsByArray($choosen);

			$line->venue = $venues[$i];
			$this->tournament_id = $venues[$i]["tournament_id"];
			$this->DRAW[] = $line;
		}


		/**
		 * Now start improving that initial set
		 * Go through the Draw until you can't make any improvements
		 */
		Yii::beginProfile("optimizeTeamAllocation");
		$stillFoundASwap = true;
		while ($stillFoundASwap) {
			$stillFoundASwap = false; //Assume we are done, prove me wrong

			$maxIterations = count($this->DRAW);
			for ($lineIterator = 0; $lineIterator < $maxIterations; $lineIterator++) {
				for ($teamIterator = 0; $teamIterator < 4; $teamIterator++) {

					$posBadness = Team::getPositionBadness($teamIterator, $this->DRAW[$lineIterator]->teams[$teamIterator]);
					if ($posBadness > 0) { // Not optimal positioning exists here
						if ($this->find_best_team_swap_for($this->DRAW[$lineIterator], $teamIterator)) { //Do we find a swap that makes it better
							$stillFoundASwap = true; //We found a better swap, do the loop again
							break;
						}
					}

				}
				if ($stillFoundASwap)
					break; //Found it already break on!
			}
			if (memory_get_usage() > $memory_limit) {
				$stillFoundASwap = false;
				Yii::$app->session->addFlash("error", "Abort <b>Team</b> optimization due to memory limit: " . memory_get_usage() / 1024 / 1024);
			}

			//If we havn't found a better swap $stillFoundASwap should be false and the loop breaks
		}
		Yii::endProfile("optimizeTeamAllocation");

		/*
		 * Allocate the Adjudicators
		 */
		$lineID = 0;
		foreach ($adjudicators as $adj) {
			$this->DRAW[$lineID]->addAdjudicator($adj);

			if (isset($this->DRAW[$lineID + 1])) //Is there a next line
				$lineID++;
			else
				$lineID = 0; //Start again at beginning
		}

		$maxIterations = count($this->DRAW);
		for ($lineIterator = 0; $lineIterator < $maxIterations; $lineIterator++) {
			$this->DRAW[$lineIterator] = $this->calcEnergyLevel($this->DRAW[$lineIterator]);
		}

		/**
		 * Now start improving that initial set
		 * Go through the Draw until you can't make any improvements
		 */
		Yii::beginProfile("optimizeAdjudicatorAllocation");
		$maxIterations = count($this->DRAW);

		$stillFoundASwap = true;
		while ($stillFoundASwap) {
			$stillFoundASwap = false; //Assume we are done, prove me wrong

			for ($lineIterator = 0; $lineIterator < $maxIterations; $lineIterator++) {
				$maxAdjuIteration = count($this->DRAW[$lineIterator]->getAdjudicators());
				for ($adjuIterator = 0; $adjuIterator < $maxAdjuIteration; $adjuIterator++) {

					if($this->find_best_adju_swap_for($this->DRAW[$lineIterator], $adjuIterator))
					{
						$stillFoundASwap = true; //We found a better swap, do the loop again
						break;
					}

				}
				if ($stillFoundASwap)
					break; //Found it already break on!
			}
			if (memory_get_usage() > $memory_limit) {
				$stillFoundASwap = false;
				Yii::$app->session->addFlash("error", "Abort <b>Adjudicator</b> optimization due to memory limit: " . memory_get_usage() / 1024 / 1024);
			}
			//If we havn't found a better swap $stillFoundASwap should be false and the loop breaks
		}
		Yii::endProfile("optimizeAdjudicatorAllocation");


		/*
		 * We have found the best possible combination
		 * There is no better swap possible now.
		 * Return der DRAW[] and get ready to debate
		 */
		Yii::endProfile("generateDraw");
		return $this->DRAW;
	}

	/**
	 * Sortiert Teams
	 *
	 * @param Team[] $teams
	 *
	 * @return Team[]
	 */
	public function sort_teams($teams) {
		//Surpress an error due to a php bug.
		@usort($teams, array('common\models\Team', 'compare_points'));
		return $teams;
	}

	/**
	 * Sortiert Adjudicator
	 *
	 * @param Adjudicator[] $adj
	 *
	 * @return Adjudicator[]
	 */
	public function sort_adjudicators($adj) {
		usort($adj, array('common\models\Adjudicator', 'compare_strength'));
		return $adj;
	}

	/**
	 * Randomises the Teams within Teampoints
	 *
	 * @param Team[] $teams
	 *
	 * @return Team[]
	 */
	public function randomise_within_points($teams) {

		$saved_points = $teams[0]["points"]; //reset to start
		$last_break = 0;

		for ($i = 0; $i < count($teams); $i++) {
			$team_points = $teams[$i]["points"];
			if ($team_points != $saved_points) {
				$bracket = array_slice($teams, $last_break, ($i - $last_break));
				shuffle($bracket);
				array_splice($teams, $last_break, ($i - $last_break), $bracket);

				$last_break = $i;
				$saved_points = $team_points;
			}
		}
		return $teams;
	}

	/**
	 * Swapps 2 Teams
	 *
	 * @param DrawLine $line_a
	 * @param integer  $pos_a
	 * @param DrawLine $line_b
	 * @param integer  $pos_b
	 */
	public function swap_teams($line_a, $pos_a, $line_b, $pos_b) {

		$team_a = $line_a->getTeamOn($pos_a);
		$team_b = $line_b->getTeamOn($pos_b);

		$line_a->setTeamOn($pos_a, $team_b);
		$line_b->setTeamOn($pos_b, $team_a);
	}

	/**
	 * Swapps 2 Adjudicator
	 *
*@param DrawLine $line_a
	 * @param integer  $pos_a
	 * @param DrawLine $line_b
	 * @param integer  $pos_b
	 */
	public function swap_adjudicator($line_a, $pos_a, $line_b, $pos_b) {

		$adju_a = $line_a->getAdjudicator($pos_a);
		$adju_b = $line_b->getAdjudicator($pos_b);

		$line_a->setAdjudicator($pos_a, $adju_b);
		$line_b->setAdjudicator($pos_b, $adju_a);
	}

	/**
	 * @param DrawLine $line_a
	 * @param integer  $pos_a
	 *
	 * @return boolean
	 */
	public function find_best_team_swap_for($line_a, $pos_a) {
		/** @var Team $team_a */
		$team_a = $line_a->getTeamOn($pos_a);
		$best_effect = 0;
		$best_team_b_line = false;
		$best_team_b_pos = false;

		$team_a_badness = Team::getPositionBadness($pos_a, $team_a);

		$maxIterations = count($this->DRAW);
		for ($lineIterator = 0; $lineIterator < $maxIterations; $lineIterator++) {
			for ($teamIterator = 0; $teamIterator < 4; $teamIterator++) {
				//foreach ($this->DRAW as $line) {
				//foreach ($line->getTeams() as $pos_b => $team_b) { //this loop especially can be limited
				if (Team::is_swappable_with(
					$team_a,
					$this->DRAW[$lineIterator]->teams[$teamIterator],
					$line_a->level,
					$this->DRAW[$lineIterator]->level)
				) {

					//Get Status Quo Badness
					$current = $team_a_badness + Team::getPositionBadness($teamIterator, $this->DRAW[$lineIterator]->teams[$teamIterator]);
					//How it would look like
					$future = Team::getPositionBadness($teamIterator, $team_a) + Team::getPositionBadness($pos_a, $this->DRAW[$lineIterator]->teams[$teamIterator]);

					$net_effect = $future - $current;
					if ($net_effect < $best_effect) {
						$best_effect = $net_effect;
						$best_team_b_line = $this->DRAW[$lineIterator];
						$best_team_b_pos = $teamIterator;
					}
				}
			}
		}

		if ($best_team_b_line && $best_team_b_pos) {
			$this->swap_teams($line_a, $pos_a, $best_team_b_line, $best_team_b_pos);
			return true;
		}
		return false;
	}

	/**
	 * @param DrawLine $line_a
	 * @param integer  $pos_a
	 *
	 * @return bool
	 */
	public function find_best_adju_swap_for($line_a, $pos_a) {

		Yii::beginProfile("find_best_adju_swap_for");
		$best_effect = 0;
		$best_adju_b_line = false;
		$best_adju_b_pos = false;

		$line_a_strength = $line_a->getStrength();

		$maxIterations = count($this->DRAW);
		for ($lineIterator = 0; $lineIterator < $maxIterations; $lineIterator++) {
			$maxAdjudicator = count($this->DRAW[$lineIterator]->getAdjudicators());
			for ($adjuIterator = 0; $adjuIterator < $maxAdjudicator; $adjuIterator++) {

				$currentEnergy = $line_a_strength + $this->DRAW[$lineIterator]->getStrength();

				//Create new lines for future
				$new_line_a = $line_a;
				$new_line_b = $this->DRAW[$lineIterator];

				//Swap the adjudicators
				$this->swap_adjudicator($new_line_a, $pos_a, $new_line_b, $adjuIterator);

				//Calculate New Energy Levels
				$this->calcEnergyLevel($new_line_a);
				$this->calcEnergyLevel($new_line_b);
				$futureEnergy = $new_line_a->getStrength() + $new_line_b->getStrength();

				$net_effect = $futureEnergy - $currentEnergy;
				if ($net_effect < $best_effect) {
					$best_effect = $net_effect;
					$best_adju_b_line = $this->DRAW[$lineIterator];
					$best_adju_b_pos = $adjuIterator;
				}
			}
		}

		Yii::endProfile("find_best_adju_swap_for");
		if ($best_adju_b_line && $best_adju_b_pos && $best_adju_b_line != $line_a && $best_adju_b_pos != $pos_a) {
			$this->swap_adjudicator($line_a, $pos_a, $best_adju_b_line, $best_adju_b_pos);
			return true;
		}
		return false;
	}

	/**
	 * Sets up the variables in the EnergyConfig

	 *
*@param Tournament $tournament
	 *
	 * @return boolean
	 */
	public function setup($tournament) {
		$tid = $tournament->id;
		$config = [
			[
				"label" => "Team and adjudicator in same society penalty",
				"key" => "society_strike",
				"value" => 1000,
			],
			[
				"label" => "Adjudicators are clashed",
				"key" => "adjudicator_strike",
				"value" => 1000,
			],
			[
				"label" => "Team with Adjudicator is clashed",
				"key" => "team_strike",
				"value" => 1000,
			],
			[
				"label" => "Adjudicator is not allowed to chair",
				"key" => "non_chair",
				"value" => 1000,
			],
			[
				"label" => "Chair is not perfect at the current situation",
				"key" => "chair_not_perfect",
				"value" => 100,
			],
			[
				"label" => "Adjudicator has already judged in this combination",
				"key" => "judge_met_judge",
				"value" => 100,
			],
			[
				"label" => "Adjudicator has seen the team already",
				"key" => "judge_met_team",
				"value" => 20,
			]
		];

		foreach ($config as $c) {
			$strike = new EnergyConfig();
			$strike->tournament_id = $tid;
			$strike->label = $c["label"];
			$strike->key = $c["key"];
			$strike->value = $c["value"];
			if (!$strike->save())
				throw new Exception("Error saving EnergyConfig " . print_r($strike->getErrors(), true));
		}
		return true;
	}

	/**
	 * @param DrawLine $line
	 *
	 * @return DrawLine
	 */
	public function calcEnergyLevel($line) {
		$line->energyLevel = 0;
		$line->messages = [];
		foreach (get_class_methods($this) as $function) {
			if (strpos($function, "energyRule_") === 0) {
				$line = \call_user_func([StrictWUDCRules::className(), $function], $line);
			}
		}
		return $line;
	}

	/**
	 * Adds the society strike penalty
	 *
	 * @param DrawLine $line
	 *
	 * @return DrawLine
	 */
	public function energyRule_SameSocietyStrikes($line) {

		$penalty = $this->energyConfig["society_strike"]; // EnergyConfig::get("society_strike", $this->tournament_id);
		foreach ($line->getAdjudicators() as $adjudicator) {
			foreach ($line->getTeams() as $team) {
				if ($team["society_id"] == $adjudicator["society_id"]) {
					$line->addMessage("error", "Adjudicator " . $adjudicator["name"] . " and " . $team["name"] . " in same society (+$penalty)");
					$line->energyLevel += $penalty;
				}
			}
		}

		return $line;
	}

	/**
	 * Adds the adjudicator strike penalty
	 *
	 * @param DrawLine $line
	 *
	 * @return DrawLine
	 */
	public function energyRule_AdjudicatorStrikes($line) {

		$penalty = $this->energyConfig["adjudicator_strike"]; //EnergyConfig::get("adjudicator_strike", $this->tournament_id);

		foreach ($line->getAdjudicators() as $adjudicator) {
			foreach ($adjudicator["strikedAdjudicators"] as $adjudicator_check) {
				if ($adjudicator["id"] == $adjudicator_check["id"]) {
					$line->addMessage("error", "Adjudicator #" . $adjudicator["name"] . " and #" . $adjudicator_check["name"] . " are manually clashed (+$penalty)");
					$line->energyLevel += $penalty;
				}
			}
		}

		return $line;
	}

	/**
	 * Adds the adjudicator <-> team strike penalty
	 *
	 * @param DrawLine $line
	 *
	 * @return DrawLine
	 */
	public function energyRule_TeamAdjStrikes($line) {

		$penalty = $this->energyConfig["team_strike"]; // EnergyConfig::get("team_strike", $this->tournament_id);

		foreach ($line->getAdjudicators() as $adjudicator) {
			foreach ($adjudicator["strikedTeams"] as $team_check) {
				foreach ($line->getTeams() as $team) {
					if ($team["id"] == $team_check["id"]) {
						$line->addMessage("error", "Adjudicator " . $adjudicator["name"] . " and Team " . $team["name"] . " are manually clashed (+$penalty)");
						$line->energyLevel += $penalty;
					}
				}
			}
		}

		return $line;
	}

	/**
	 * Adds the non-chair in the chair penalty
	 *
	 * @param DrawLine $line
	 *
	 * @return DrawLine
	 */
	public function energyRule_NonChair($line) {

		$penalty = $this->energyConfig["non_chair"]; // EnergyConfig::get("non_chair", $this->tournament_id);
		//This relies on there being a 'can_chair' tag
		if ($line->getChair()["can_chair"] == 0) {
			$line->addMessage("error", "Adjudicator " . $line->getChair()["name"] . " has been labelled a non-chair (+$penalty)");
			$line->energyLevel += $penalty;
		}

		return $line;
	}

	/**
	 * Adds the chair not perfect penalty
	 *
	 * @param DrawLine $line
	 *
	 * @return DrawLine
	 */
	public function energyRule_NotPerfect($line) {

		$penalty = $this->energyConfig["chair_not_perfect"]; //EnergyConfig::get("chair_not_perfect", $this->tournament_id);

		//This basically adds a penalty for each point away from the maximum the chair's ranking is
		$diffPerfect = (Adjudicator::MAX_RATING - $line->getChair()["strength"]);

		if ($diffPerfect > 0) {
			$comp_penalty = ($penalty * $diffPerfect);
			$line->addMessage("warning", "Chair not perfect by " . $diffPerfect . " (+$comp_penalty)");
			$line->energyLevel += $comp_penalty;
		}
		return $line;
	}

	/**
	 * Adds the judge met judge penalty
	 *
	 * @param DrawLine $line
	 *
	 * @return DrawLine
	 */
	public function energyRule_JudgeMetJudge($line) {

		$penalty = $this->energyConfig["judge_met_judge"]; // EnergyConfig::get("judge_met_judge", $this->tournament_id);
		$found = [];
		foreach ($line->getAdjudicators() as $adjudicator) {
			foreach ($line->getAdjudicators() as $adjudicator_match) {

				if ($adjudicator_match["id"] != $adjudicator["id"]) {
					if (in_array($adjudicator_match["id"], $adjudicator["pastAdjudicatorIDs"])) {

						if (!in_array($adjudicator_match["id"], $found)) {
							$found[] = $adjudicator_match["id"];
							$line->addMessage("warning", "Adjudicator " .
								$adjudicator["name"] . " and " .
								$adjudicator_match["name"] .
								" have judged together before (+$penalty)");
							$line->energyLevel += $penalty;
						}
					}
				}

			}

		}
		return $line;
	}

	/**
	 * Adds the judge met team penalty
	 *
	 * @param DrawLine $line
	 *
	 * @return DrawLine
	 */
	public function energyRule_JudgeMetTeam($line) {

		$penalty = $this->energyConfig["judge_met_team"]; // EnergyConfig::get("judge_met_team", $this->tournament_id);
		foreach ($line->getAdjudicators() as $adjudicator) {
			foreach ($line->getTeams() as $team) {
				if (in_array($team["id"], $adjudicator["pastTeamIDs"])) {
					$line->addMessage("warning", "Adjudicator " . $adjudicator["name"] . " has judged Team " . $team["name"] . " before (+$penalty)");
					$line->energyLevel += $penalty;
				}
			}
		}

		return $line;
	}
 
 	/**
	 * Adds the panel strength penalty
	 *
	 * @param DrawLine $line
	 *
	 * @return DrawLine
	 */
	public function energyRule_PanelSteepness($line) {

		//$penalty = EnergyConfig::get("panel_steepness", $round->tournament_id);

		//First, we need to calculate how good the room is

		$roomPotential = $line->getLevel() - ($this->round_number - 1) * 2;

		// This will convert the level of the room into +1, +2, -1 etc. This is useful, because we want the judging to be relative to this level.
		// The equation we use is: SD = (x-1)*log(abs((x-1)))+1, where x is the 'Room Potential' and SD is the number of SDs that average is from the mean.

		$roomDifference = ($roomPotential-1)*log(abs(($roomPotential-1)))+1;

		//So now we need to work out where this sits on the scale

		$comparison_factor = ($line->getStrength() - $this->average_adjudicator_strength) / $this->SD_of_adjudicators;

		$penalty = intval(pow(($roomDifference - $comparison_factor), 2));
		$line->addMessage("notice", "Steepness Comparison: " . round($comparison_factor, 3) . ", Difference: " . round($roomDifference, 3) . " (+$penalty)");
		$line->energyLevel += $penalty;
		return $line;
	}


}