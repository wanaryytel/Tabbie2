<?php

use yii\helpers\Html;

/* @var $this yii\web\View */
/* @var $model common\models\Strikes */

$this->title = Yii::t('app', 'Update {modelClass}', [
	'modelClass' => 'Adjudicator Strikes',
]);
$tournament = $this->context->_getContext();
$this->params['breadcrumbs'][] = ['label' => $tournament->fullname, 'url' => ['tournament/view', "id" => $tournament->id]];
$this->params['breadcrumbs'][] = ['label' => Yii::t('app', 'Strikes'), 'url' => ['adjudicator_index', "tournament_id" => $tournament->id]];
$this->params['breadcrumbs'][] = Yii::t('app', 'Update');
?>
<div class="strikes-update">

	<h1><?= Html::encode($this->title) ?></h1>

	<?= $this->render('_adjudicator_form', [
		'model' => $model,
	]) ?>

</div>
