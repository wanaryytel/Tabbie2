SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL,ALLOW_INVALID_DATES';

-- -----------------------------------------------------
-- Table `user`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `user` ;

CREATE TABLE IF NOT EXISTS `user` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `username` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL,
  `auth_key` VARCHAR(32) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL,
  `password_hash` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL,
  `password_reset_token` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NULL DEFAULT NULL,
  `email` VARCHAR(255) CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci' NOT NULL,
  `role` SMALLINT(6) NOT NULL DEFAULT '10',
  `status` SMALLINT(6) NOT NULL DEFAULT '10',
  `givenname` VARCHAR(255) NULL,
  `surename` VARCHAR(255) NULL,
  `picture` VARCHAR(255) NULL,
  `last_change` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  `time` DATETIME NOT NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `tournament`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `tournament` ;

CREATE TABLE IF NOT EXISTS `tournament` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `url_slug` VARCHAR(100) NOT NULL,
  `convenor_user_id` INT(11) UNSIGNED NOT NULL,
  `tabmaster_user_id` INT(11) UNSIGNED NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `start_date` DATETIME NOT NULL,
  `end_date` DATETIME NOT NULL,
  `logo` VARCHAR(255) NULL,
  `time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_tournament_user1_idx` (`convenor_user_id` ASC),
  INDEX `fk_tournament_user2_idx` (`tabmaster_user_id` ASC),
  UNIQUE INDEX `slug_UNIQUE` (`url_slug` ASC),
  CONSTRAINT `fk_tournament_user1`
    FOREIGN KEY (`convenor_user_id`)
    REFERENCES `user` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_tournament_user2`
    FOREIGN KEY (`tabmaster_user_id`)
    REFERENCES `user` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `society`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `society` ;

CREATE TABLE IF NOT EXISTS `society` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `fullname` VARCHAR(255) NULL,
  `adr` VARCHAR(45) NULL,
  `city` VARCHAR(255) NULL,
  `country` VARCHAR(255) NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `adr_UNIQUE` (`adr` ASC))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `adjudicator`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adjudicator` ;

CREATE TABLE IF NOT EXISTS `adjudicator` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tournament_id` INT UNSIGNED NOT NULL,
  `user_id` INT UNSIGNED NOT NULL,
  `strength` TINYINT NULL,
  `society_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_adjudicator_username1_idx` (`user_id` ASC),
  INDEX `fk_adjudicator_tournament1_idx` (`tournament_id` ASC),
  INDEX `fk_adjudicator_society1_idx` (`society_id` ASC),
  CONSTRAINT `fk_adjudicator_username1`
    FOREIGN KEY (`user_id`)
    REFERENCES `user` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_adjudicator_tournament1`
    FOREIGN KEY (`tournament_id`)
    REFERENCES `tournament` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_adjudicator_society1`
    FOREIGN KEY (`society_id`)
    REFERENCES `society` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `team`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `team` ;

CREATE TABLE IF NOT EXISTS `team` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NULL,
  `tournament_id` INT UNSIGNED NOT NULL,
  `speakerA_id` INT UNSIGNED NOT NULL,
  `speakerB_id` INT UNSIGNED NOT NULL,
  `society_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_team_username_idx` (`speakerA_id` ASC),
  INDEX `fk_team_username1_idx` (`speakerB_id` ASC),
  INDEX `fk_team_tournament1_idx` (`tournament_id` ASC),
  INDEX `fk_team_society1_idx` (`society_id` ASC),
  CONSTRAINT `fk_team_username`
    FOREIGN KEY (`speakerA_id`)
    REFERENCES `user` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_team_username1`
    FOREIGN KEY (`speakerB_id`)
    REFERENCES `user` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_team_tournament1`
    FOREIGN KEY (`tournament_id`)
    REFERENCES `tournament` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_team_society1`
    FOREIGN KEY (`society_id`)
    REFERENCES `society` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `round`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `round` ;

CREATE TABLE IF NOT EXISTS `round` (
  `id` INT UNSIGNED NOT NULL,
  `tournament_id` INT UNSIGNED NOT NULL,
  `motion` TEXT NOT NULL,
  `infoslide` TEXT NULL,
  `time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `published` TINYINT(1) NOT NULL DEFAULT 0,
  `displayed` TINYINT(1) NOT NULL DEFAULT 0,
  `closed` TINYINT(1) NOT NULL DEFAULT 0,
  `prep_started` DATETIME NULL,
  `finished_time` DATETIME NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_round_tournament1_idx` (`tournament_id` ASC),
  CONSTRAINT `fk_round_tournament1`
    FOREIGN KEY (`tournament_id`)
    REFERENCES `tournament` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `venue`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `venue` ;

CREATE TABLE IF NOT EXISTS `venue` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tournament_id` INT UNSIGNED NOT NULL,
  `name` VARCHAR(100) NOT NULL,
  `active` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  INDEX `fk_venue_tournament1_idx` (`tournament_id` ASC),
  CONSTRAINT `fk_venue_tournament1`
    FOREIGN KEY (`tournament_id`)
    REFERENCES `tournament` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `panel`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `panel` ;

CREATE TABLE IF NOT EXISTS `panel` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `strength` INT NOT NULL DEFAULT 0,
  `time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `tournament_id` INT UNSIGNED NOT NULL,
  `used` TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  INDEX `fk_panel_tournament1_idx` (`tournament_id` ASC),
  CONSTRAINT `fk_panel_tournament1`
    FOREIGN KEY (`tournament_id`)
    REFERENCES `tournament` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `debate`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `debate` ;

CREATE TABLE IF NOT EXISTS `debate` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `round_id` INT UNSIGNED NOT NULL,
  `tournament_id` INT UNSIGNED NOT NULL,
  `og_team_id` INT UNSIGNED NOT NULL,
  `oo_team_id` INT UNSIGNED NOT NULL,
  `cg_team_id` INT UNSIGNED NOT NULL,
  `co_team_id` INT UNSIGNED NOT NULL,
  `panel_id` INT UNSIGNED NOT NULL,
  `venue_id` INT UNSIGNED NOT NULL,
  `og_feedback` TINYINT(1) NOT NULL DEFAULT 0,
  `oo_feedback` TINYINT(1) NOT NULL DEFAULT 0,
  `cg_feedback` TINYINT(1) NOT NULL DEFAULT 0,
  `co_feedback` TINYINT(1) NOT NULL DEFAULT 0,
  `time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_debate_venue1_idx` (`venue_id` ASC),
  INDEX `fk_debate_panel1_idx` (`panel_id` ASC),
  CONSTRAINT `fk_debate_venue1`
    FOREIGN KEY (`venue_id`)
    REFERENCES `venue` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_debate_panel1`
    FOREIGN KEY (`panel_id`)
    REFERENCES `panel` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `result`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `result` ;

CREATE TABLE IF NOT EXISTS `result` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `debate_id` INT UNSIGNED NOT NULL,
  `og_speaks` TINYINT NOT NULL,
  `og_place` TINYINT NULL,
  `oo_speaks` TINYINT NOT NULL,
  `oo_place` TINYINT NULL,
  `cg_speaks` TINYINT NOT NULL,
  `cg_place` TINYINT NULL,
  `co_speaks` TINYINT NOT NULL,
  `co_place` TINYINT NULL,
  `time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_result_debate1_idx` (`debate_id` ASC),
  CONSTRAINT `fk_result_debate1`
    FOREIGN KEY (`debate_id`)
    REFERENCES `debate` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `in_society`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `in_society` ;

CREATE TABLE IF NOT EXISTS `in_society` (
  `user_id` INT(10) UNSIGNED NOT NULL,
  `society_id` INT UNSIGNED NOT NULL,
  `starting` DATE NOT NULL,
  `ending` DATE NULL,
  PRIMARY KEY (`society_id`, `user_id`),
  INDEX `fk_username_has_university_university1_idx` (`society_id` ASC),
  INDEX `fk_username_has_university_username1_idx` (`user_id` ASC),
  CONSTRAINT `fk_username_in_society_society1`
    FOREIGN KEY (`society_id`)
    REFERENCES `society` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_username_in_society_username1`
    FOREIGN KEY (`user_id`)
    REFERENCES `user` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `special_needs`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `special_needs` ;

CREATE TABLE IF NOT EXISTS `special_needs` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(255) NULL,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `username_has_special_needs`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `username_has_special_needs` ;

CREATE TABLE IF NOT EXISTS `username_has_special_needs` (
  `username_id` INT UNSIGNED NOT NULL,
  `special_needs_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`username_id`, `special_needs_id`),
  INDEX `fk_username_has_special_needs_special_needs1_idx` (`special_needs_id` ASC),
  INDEX `fk_username_has_special_needs_username1_idx` (`username_id` ASC),
  CONSTRAINT `fk_username_has_special_needs_username1`
    FOREIGN KEY (`username_id`)
    REFERENCES `user` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_username_has_special_needs_special_needs1`
    FOREIGN KEY (`special_needs_id`)
    REFERENCES `special_needs` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `draw_after_round`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `draw_after_round` ;

CREATE TABLE IF NOT EXISTS `draw_after_round` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `tournament_id` INT UNSIGNED NOT NULL,
  `round_id` INT UNSIGNED NOT NULL,
  `time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_draw_tournament1_idx` (`tournament_id` ASC),
  INDEX `fk_draw_round1_idx` (`round_id` ASC),
  CONSTRAINT `fk_draw_tournament1`
    FOREIGN KEY (`tournament_id`)
    REFERENCES `tournament` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_draw_round1`
    FOREIGN KEY (`round_id`)
    REFERENCES `round` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `draw_position`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `draw_position` ;

CREATE TABLE IF NOT EXISTS `draw_position` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `draw_id` INT UNSIGNED NOT NULL,
  `team_id` INT UNSIGNED NOT NULL,
  `result_id` INT UNSIGNED NOT NULL,
  `points` INT NOT NULL,
  `speakerA_speaks` INT NOT NULL,
  `speakerB_speaks` INT NOT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_draw_position_team1_idx` (`team_id` ASC),
  INDEX `fk_draw_position_draw1_idx` (`draw_id` ASC),
  INDEX `fk_draw_position_result1_idx` (`result_id` ASC),
  CONSTRAINT `fk_draw_position_team1`
    FOREIGN KEY (`team_id`)
    REFERENCES `team` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_draw_position_draw1`
    FOREIGN KEY (`draw_id`)
    REFERENCES `draw_after_round` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_draw_position_result1`
    FOREIGN KEY (`result_id`)
    REFERENCES `result` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `venue_provides_special_needs`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `venue_provides_special_needs` ;

CREATE TABLE IF NOT EXISTS `venue_provides_special_needs` (
  `venue_id` INT UNSIGNED NOT NULL,
  `special_needs_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`venue_id`, `special_needs_id`),
  INDEX `fk_venue_has_special_needs_special_needs1_idx` (`special_needs_id` ASC),
  INDEX `fk_venue_has_special_needs_venue1_idx` (`venue_id` ASC),
  CONSTRAINT `fk_venue_has_special_needs_venue1`
    FOREIGN KEY (`venue_id`)
    REFERENCES `venue` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_venue_has_special_needs_special_needs1`
    FOREIGN KEY (`special_needs_id`)
    REFERENCES `special_needs` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `questions`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `questions` ;

CREATE TABLE IF NOT EXISTS `questions` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `text` VARCHAR(45) NOT NULL,
  `type` INT NOT NULL,
  `apply_T2C` TINYINT(1) NOT NULL DEFAULT 0,
  `apply_C2W` TINYINT(1) NOT NULL DEFAULT 0,
  `apply_W2C` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `tournament_has_questions`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `tournament_has_questions` ;

CREATE TABLE IF NOT EXISTS `tournament_has_questions` (
  `tournament_id` INT UNSIGNED NOT NULL,
  `questions_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`tournament_id`, `questions_id`),
  INDEX `fk_tournament_has_questions_questions1_idx` (`questions_id` ASC),
  INDEX `fk_tournament_has_questions_tournament1_idx` (`tournament_id` ASC),
  CONSTRAINT `fk_tournament_has_questions_tournament1`
    FOREIGN KEY (`tournament_id`)
    REFERENCES `tournament` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_tournament_has_questions_questions1`
    FOREIGN KEY (`questions_id`)
    REFERENCES `questions` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `adjudicator_in_panel`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `adjudicator_in_panel` ;

CREATE TABLE IF NOT EXISTS `adjudicator_in_panel` (
  `adjudicator_id` INT UNSIGNED NOT NULL,
  `panel_id` INT UNSIGNED NOT NULL,
  `function` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`adjudicator_id`, `panel_id`),
  INDEX `fk_adjudicator_has_panel_panel1_idx` (`panel_id` ASC),
  INDEX `fk_adjudicator_has_panel_adjudicator1_idx` (`adjudicator_id` ASC),
  CONSTRAINT `fk_adjudicator_has_panel_adjudicator1`
    FOREIGN KEY (`adjudicator_id`)
    REFERENCES `adjudicator` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_adjudicator_has_panel_panel1`
    FOREIGN KEY (`panel_id`)
    REFERENCES `panel` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `feedback`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `feedback` ;

CREATE TABLE IF NOT EXISTS `feedback` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `debate_id` INT UNSIGNED NOT NULL,
  `time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `fk_feedback_debate1_idx` (`debate_id` ASC),
  CONSTRAINT `fk_feedback_debate1`
    FOREIGN KEY (`debate_id`)
    REFERENCES `debate` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `answer`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `answer` ;

CREATE TABLE IF NOT EXISTS `answer` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `questions_id` INT UNSIGNED NOT NULL,
  `value` TEXT NULL,
  PRIMARY KEY (`id`),
  INDEX `fk_answer_questions1_idx` (`questions_id` ASC),
  CONSTRAINT `fk_answer_questions1`
    FOREIGN KEY (`questions_id`)
    REFERENCES `questions` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `feedback_has_answer`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `feedback_has_answer` ;

CREATE TABLE IF NOT EXISTS `feedback_has_answer` (
  `feedback_id` INT UNSIGNED NOT NULL,
  `answer_id` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`feedback_id`, `answer_id`),
  INDEX `fk_feedback_has_answer_answer1_idx` (`answer_id` ASC),
  INDEX `fk_feedback_has_answer_feedback1_idx` (`feedback_id` ASC),
  CONSTRAINT `fk_feedback_has_answer_feedback1`
    FOREIGN KEY (`feedback_id`)
    REFERENCES `feedback` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_feedback_has_answer_answer1`
    FOREIGN KEY (`answer_id`)
    REFERENCES `answer` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table `strikes`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `strikes` ;

CREATE TABLE IF NOT EXISTS `strikes` (
  `team_id` INT UNSIGNED NOT NULL,
  `adjudicator_id` INT UNSIGNED NOT NULL,
  `approved` TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`team_id`, `adjudicator_id`),
  INDEX `fk_team_has_adjudicator_adjudicator1_idx` (`adjudicator_id` ASC),
  INDEX `fk_team_has_adjudicator_team1_idx` (`team_id` ASC),
  CONSTRAINT `fk_team_has_adjudicator_team1`
    FOREIGN KEY (`team_id`)
    REFERENCES `team` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_team_has_adjudicator_adjudicator1`
    FOREIGN KEY (`adjudicator_id`)
    REFERENCES `adjudicator` (`id`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;