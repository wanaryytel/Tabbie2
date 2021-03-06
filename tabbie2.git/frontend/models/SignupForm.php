<?php

namespace frontend\models;

use common\models\InSociety;
use common\models\User;
use Yii;
use yii\base\Model;
use yii\helpers\Html;
use yii\web\UploadedFile;

/**
 * Signup form
 */
class SignupForm extends Model
{

	public $email;
	public $password;
	public $password_repeat;
	public $surename;
	public $givenname;
	public $societies_id;
	public $gender;
	public $picture;

	/**
	 * @inheritdoc
	 */
	public function rules()
	{
		return [
			[['password', 'password_repeat', 'email', 'givenname', 'surename', 'societies_id'], 'required'],
			['email', 'email'],
			['email', 'unique', 'targetClass' => '\common\models\User', 'message' => Yii::t("app", 'This email address has already been taken.')],
			['password_repeat', 'compare', 'compareAttribute' => 'password'],
			['gender', 'default', 'value' => User::GENDER_NOTREVEALING],
			['gender', 'in', 'range' => [User::GENDER_MALE, User::GENDER_FEMALE, User::GENDER_OTHER, User::GENDER_NOTREVEALING]],
			[['picture'], 'string'],
			[['societies_id'], 'safe'],
			[['email', 'givenname', 'surename'], 'string', 'max' => 255],
		];
	}

	/**
	 * @inheritdoc
	 */
	public function attributeLabels()
	{
		return [
			'url_slug'     => Yii::t('app', 'Username'),
			'email'        => Yii::t('app', 'Email'),
			'givenname'    => Yii::t('app', 'First Name'),
			'surename'     => Yii::t('app', 'Last Name'),
			'picture'      => Yii::t('app', 'Profile Picture'),
			'time'         => Yii::t('app', 'Time'),
			'societies_id' => Yii::t('app', 'Current Society'),
			'gender'       => Yii::t('app', 'With which gender do you identify yourself the most'),
		];
	}

	/**
	 * Check if the URL is allowed or if there are any conflicts with Actions
	 *
	 * @param type $attribute
	 * @param type $params
	 */
	public function validateIsUrlAllowed($attribute, $params)
	{
		foreach (get_class_methods(\frontend\controllers\UserController::className()) as $key => $value) {
			if (substr($value, 0, 6) == "action" && $value != "actions") {
				$actions[] = strtolower(substr($value, 6));
			}
		}

		if (in_array($this->$attribute, $actions)) {
			$this->addError($attribute, Yii::t("app", 'This URL is not allowed.'));
		}
	}

	/**
	 * Signs user up.
	 *
	 * @return User|null the saved model or null if saving fails
	 */
	public function signup()
	{
		if ($this->validate()) {

			$pic = UploadedFile::getInstance($this, "picture");

			$user = new User();
			$user->email = $this->email;
			$user->setPassword($this->password);
			$user->generateAuthKey();
			$user->time = $user->last_change = date("Y-m-d H:i:s");
			$user->surename = $this->surename;
			$user->givenname = $this->givenname;
			$user->gender = $this->gender;
			$user->url_slug = $user->generateUrlSlug();

			if ($pic instanceof UploadedFile)
				$user->savePicture($pic);
			else
				$user->picture = null;

			if ($user->save()) {
				$inSociety = new InSociety([
					"user_id"  => $user->id,
					"society_id" => $this->societies_id,
					"starting" => date("Y-m-d"),
				]);
				$inSociety->save();

				return $user;
			}
		}

		return null;
	}

	public function getPictureImage($width_max, $height_max)
	{
		$img_options = ["alt"    => "",
						"style"  => "max-width: " . $width_max . "px; max-height: " . $height_max . "px;",
						"width"  => $width_max,
						"height" => $height_max,
						"id"     => "previewImageUpload",
		];
		$img_options["class"] = "img-responsive img-rounded center-block";

		return Html::img(User::defaultAvatar(), $img_options);
	}

}
