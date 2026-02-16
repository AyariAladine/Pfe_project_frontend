import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'ar': {
      // App
      'appName': 'عقاري',

      // Auth
      'welcomeBack': 'مرحباً بعودتك',
      'loginToAccount': 'تسجيل الدخول إلى حسابك',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'forgotPassword': 'نسيت كلمة المرور؟',
      'login': 'تسجيل الدخول',
      'signUp': 'إنشاء حساب',
      'orContinueWith': 'أو المتابعة عبر',
      'or': 'أو',
      'continueWithGoogle': 'المتابعة بحساب جوجل',
      'googleSignInFailed': 'فشل تسجيل الدخول بجوجل',
      'dontHaveAccount': 'ليس لديك حساب؟',
      'alreadyHaveAccount': 'لديك حساب بالفعل؟',
      'createAccount': 'إنشاء حساب جديد',
      'fullName': 'الاسم الكامل',
      'confirmPassword': 'تأكيد كلمة المرور',
      'phoneNumber': 'رقم الهاتف',
      'resetPassword': 'إعادة تعيين كلمة المرور',
      'sendResetLink': 'إرسال رابط الإستعادة',
      'enterEmailToReset': 'أدخل بريدك الإلكتروني لإعادة تعيين كلمة المرور',
      'backToLogin': 'العودة لتسجيل الدخول',
      'signInWithGoogle': 'تسجيل الدخول بجوجل',
      'selectAccountType': 'اختر نوع الحساب',
      'selectAccountTypeSubtitle': 'اختر الخيار الأنسب لك',
      'fillYourDetails': 'أدخل بياناتك للمتابعة',
      'landlord': 'مالك عقار',
      'tenant': 'مستأجر',
      'lawyer': 'محامي',
      'user': 'مستخدم',
      'agreeToTerms': 'بالمتابعة، أنت توافق على',
      'termsOfService': 'شروط الخدمة',
      'and': 'و',
      'privacyPolicy': 'سياسة الخصوصية',
      'emailSent': 'تم إرسال البريد الإلكتروني',
      'checkInbox': 'تحقق من صندوق الوارد لإعادة تعيين كلمة المرور',

      // New Auth Strings
      'firstName': 'الاسم الأول',
      'lastName': 'اسم العائلة',
      'identityNumber': 'رقم الهوية',
      'identityRequired': 'رقم الهوية مطلوب',
      'identityInvalid': 'رقم الهوية غير صالح',
      'enterVerificationCode': 'أدخل رمز التحقق',
      'verificationCodeSent': 'تم إرسال رمز التحقق إلى بريدك الإلكتروني',
      'newPassword': 'كلمة المرور الجديدة',
      'enterNewPassword': 'أدخل كلمة المرور الجديدة',
      'sendVerificationCode': 'إرسال رمز التحقق',
      'verificationCode': 'رمز التحقق (6 أرقام)',
      'enterCode': 'الرجاء إدخال رمز التحقق',
      'codeLength': 'رمز التحقق يجب أن يكون 6 أرقام',
      'next': 'التالي',
      'resendCode': 'لم تستلم الرمز؟ إعادة الإرسال',
      'changePassword': 'تغيير كلمة المرور',
      'passwordChanged': 'تم تغيير كلمة المرور بنجاح',

      // Google Auth Role Selection
      'selectYourRole': 'اختر دورك',
      'selectRoleDescription': 'يرجى اختيار دورك للمتابعة في إنشاء حسابك',
      'landlordDescription': 'إدارة العقارات والإيجارات والعقود',
      'tenantDescription': 'البحث عن عقارات وإدارة عقود الإيجار',
      'lawyerDescription': 'تقديم الخدمات القانونية والاستشارات',
      'userDescription': 'تصفح العقارات وإدارة العقود',

      // User Types Descriptions
      'landlordDesc': 'إدارة العقارات والعقود',
      'tenantDesc': 'البحث عن عقار والتأجير',
      'lawyerDesc': 'إدارة القضايا والاستشارات',
      'userDesc': 'تصفح العقارات وإدارة العقود',

      // OCR
      'scanIdCard': 'مسح بطاقة الهوية',
      'scanFromCamera': 'التقاط صورة',
      'pickFromGallery': 'اختيار من المعرض',
      'scanning': 'جاري المسح...',
      'idNumberExtracted': 'تم استخراج رقم الهوية',
      'idNumberNotFound': 'لم يتم العثور على رقم الهوية',
      'tryAgain': 'حاول مرة أخرى',
      'cancel': 'إلغاء',

      // Home & Navigation
      'home': 'الرئيسية',
      'properties': 'العقارات',
      'contracts': 'العقود',
      'cases': 'القضايا',
      'aiAssistant': 'المساعد الذكي',
      'settings': 'الإعدادات',
      'logout': 'تسجيل الخروج',
      'welcomeToAqari': 'مرحباً بك في عقاري',
      'managePropertiesEasily': 'إدارة عقاراتك بكل سهولة',
      'quickActions': 'الإجراءات السريعة',
      'addProperty': 'إضافة عقار',
      'newContract': 'عقد جديد',
      'damageInspection': 'فحص الأضرار',
      'legalConsultation': 'استشارة قانونية',
      'recentActivity': 'النشاط الأخير',
      'noRecentActivity': 'لا يوجد نشاط حديث',
      'notificationsWillAppear': 'ستظهر هنا آخر الإشعارات والتحديثات',

      // Property Actions
      'view': 'عرض',
      'edit': 'تعديل',
      'delete': 'حذف',
      'myProperties': 'عقاراتي',
      'propertyDetails': 'تفاصيل العقار',
      'location': 'الموقع',
      'noImageAvailable': 'لا توجد صورة متاحة',
      'propertyDeleted': 'تم حذف العقار',
      'deleteProperty': 'حذف العقار',
      'deletePropertyConfirm': 'هل أنت متأكد من حذف هذا العقار؟ لا يمكن التراجع عن هذا الإجراء.',
      'forSale': 'للبيع',
      'forRent': 'للإيجار',
      'type': 'النوع',
      'status': 'الحالة',
      'locationNotSet': 'الموقع غير محدد',
      'latitude': 'خط العرض',
      'longitude': 'خط الطول',
      'openInGoogleMaps': 'فتح في خرائط جوجل',
      'propertyName': 'اسم العقار',
      'address': 'العنوان',
      'contractId': 'رقم العقد',
      'documents': 'المستندات',
      'registrationDocument': 'وثيقة التسجيل',
      'uploaded': 'تم الرفع',
      'created': 'تاريخ الإنشاء',
      'updated': 'تاريخ التحديث',
      'editProperty': 'تعديل العقار',
      'propertyAddress': 'عنوان العقار',
      'propertyType': 'نوع العقار',
      'propertyStatus': 'حالة العقار',
      'enterPropertyName': 'أدخل اسم العقار',
      'enterPropertyAddress': 'أدخل عنوان العقار',
      'enterFullAddress': 'أدخل العنوان الكامل',
      'propertyNameRequired': 'اسم العقار مطلوب',
      'propertyNameMinLength': 'اسم العقار يجب أن يكون 3 أحرف على الأقل',
      'propertyAddressRequired': 'عنوان العقار مطلوب',
      'available': 'متاح',
      'unavailable': 'غير متاح',
      'pending': 'قيد الانتظار',
      'sold': 'مباع',
      'rented': 'مؤجر',
      'clear': 'مسح',
      'selectOnMap': 'اختر على الخريطة',
      'scan': 'مسح',
      'upload': 'رفع',
      'gallery': 'المعرض',
      'camera': 'الكاميرا',
      'continue': 'متابعة',
      'continueText': 'متابعة',
      'back': 'رجوع',
      'saveChanges': 'حفظ التغييرات',
      'createProperty': 'إنشاء عقار',
      'propertyCreatedSuccessfully': 'تم إنشاء العقار بنجاح!',
      'discardChanges': 'تجاهل التغييرات؟',
      'discard': 'تجاهل',
      'changeLocation': 'تغيير الموقع',
      'chooseFromGalleryTitle': 'اختر من المعرض',
      'selectMultiplePhotos': 'اختر عدة صور',
      'takePhoto': 'التقاط صورة',
      'useCameraToCapture': 'استخدم الكاميرا للتصوير',
      'tapToChooseLocationVisually': 'انقر لاختيار الموقع بصرياً',
      'enterCoordinates': 'إدخال الإحداثيات',
      'inputLatLngManually': 'أدخل خط العرض والطول يدوياً',
      'useCurrentLocation': 'استخدم الموقع الحالي',
      'autoDetectCurrentPosition': 'كشف الموقع الحالي تلقائياً',
      'estimateFromAddress': 'تقدير من العنوان',
      'findLocationUsingAddress': 'ابحث عن الموقع باستخدام العنوان أعلاه',
      'confirmLocation': 'تأكيد الموقع',
      'latitudeHint': 'خط العرض (مثال: 36.8065)',
      'longitudeHint': 'خط الطول (مثال: 10.1815)',
      'saveLocation': 'حفظ الموقع',
      'name': 'الاسم',
      'photos': 'الصور',
      'descriptionOptional': 'الوصف (اختياري)',
      'addDetailedDescription': 'إضافة وصف تفصيلي...',
      'basicInformation': 'المعلومات الأساسية',
      'enterBasicDetails': 'أدخل التفاصيل الأساسية للعقار',
      'propertyPhotos': 'صور العقار',
      'addPhotosToShowcase': 'أضف صوراً لعرض العقار بشكل أفضل',
      'mainPhoto': 'رئيسية',
      'photosOptionalHint': 'يمكنك إضافة الصور لاحقاً من صفحة تفاصيل العقار',
      'photosAdded': 'صورة مضافة',
      'propertyLocation': 'موقع العقار',
      'setExactLocation': 'حدد الموقع الدقيق للعقار',
      'locationSet': 'تم تحديد الموقع',
      'selectOnMapTitle': 'اختر على الخريطة',
      'selectOnMapSubtitle': 'انقر لاختيار الموقع بصرياً',
      'tapOnMapOrDrag': 'انقر على الخريطة أو اسحب الدبوس',
      'selectedCoordinates': 'الإحداثيات المحددة',
      'openInGoogleMapsShort': 'فتح في خرائط جوجل',
      'enterCoordinatesTitle': 'إدخال الإحداثيات',
      'locationOptionalHint': 'الموقع اختياري، يمكنك إضافته لاحقاً',
      'notSet': 'غير محدد',
      'reviewAndCreate': 'المراجعة والإنشاء',
      'reviewPropertyDetails': 'راجع تفاصيل العقار قبل الإنشاء',
      'propertySummary': 'ملخص العقار',
      'selectLocation': 'اختر الموقع',
      'tapOnMapOrDragPin': 'انقر على الخريطة أو اسحب الدبوس',

      // Theme
      'light': 'فاتح',
      'dark': 'داكن',
      'auto': 'تلقائي',

      // Validation
      'emailRequired': 'البريد الإلكتروني مطلوب',
      'invalidEmail': 'البريد الإلكتروني غير صالح',
      'passwordRequired': 'كلمة المرور مطلوبة',
      'passwordTooShort': 'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
      'nameRequired': 'الاسم مطلوب',
      'phoneRequired': 'رقم الهاتف مطلوب',
      'passwordsDoNotMatch': 'كلمات المرور غير متطابقة',
      'accountTypeRequired': 'يرجى اختيار نوع الحساب',

      // Language
      'language': 'اللغة',
      'arabic': 'العربية',
      'english': 'English',
      'french': 'Français',

      // Error Messages
      'noInternetConnection': 'لا يوجد اتصال بالإنترنت',
      'unexpectedError': 'حدث خطأ غير متوقع',
      'loginRequired': 'يجب تسجيل الدخول',
      'invalidCredentials': 'بيانات الاعتماد غير صحيحة',
      'unauthorized': 'غير مصرح لك بهذا الإجراء',
      'notFound': 'المورد غير موجود',
      'serverError': 'خطأ في الخادم، حاول لاحقاً',
      'emailAlreadyExists': 'البريد الإلكتروني مسجل مسبقاً',
      'invalidCode': 'رمز التحقق غير صحيح',
      'codeExpired': 'انتهت صلاحية رمز التحقق',
      
      // Onboarding
      'verifyIdentity': 'التحقق من الهوية',
      'verifyIdentityDesc': 'نحتاج للتحقق من هويتك لضمان أمان حسابك وحماية معاملاتك',
      'verifyIdentitySubtitle': 'بطاقة الهوية والبصمة والجهاز',
      'getStarted': 'ابدأ الآن',
      'scanCin': 'مسح بطاقة الهوية',
      'scanCinDesc': 'قم بمسح بطاقة هويتك الوطنية لاستخراج رقم الهوية تلقائياً',
      'ocrRequiresMobileApp': 'يتطلب مسح بطاقة الهوية استخدام تطبيق الهاتف المحمول',
      'useAppForOcr': 'استخدم التطبيق للمسح',
      'uploadImage': 'رفع صورة',
      'uploadCinImage': 'ارفع صورة بطاقة هويتك',
      'scanWithCamera': 'المسح بالكاميرا',
      'takePhotoOfCin': 'التقط صورة لبطاقة هويتك',
      'chooseFromGallery': 'اختيار من المعرض',
      'selectExistingPhoto': 'اختر صورة موجودة',
      'enterManually': 'إدخال يدوي',
      'backToScan': 'العودة للمسح',
      'cinNumber': 'رقم الهوية',
      'cinDetected': 'تم اكتشاف رقم الهوية',
      'scanAgain': 'مسح مرة أخرى',
      'verify': 'تحقق',
      'setupBiometrics': 'إعداد البصمة',
      'setupBiometricsDesc': 'استخدم بصمتك لتسجيل الدخول بسرعة وأمان',
      'biometricsNotAvailableWeb': 'البصمة غير متاحة على الويب. يمكنك تخطي هذه الخطوة.',
      'enableBiometrics': 'تفعيل البصمة',
      'biometricReason': 'يرجى التحقق من هويتك',
      'skipForNow': 'تخطي الآن',
      'skip': 'تخطي',
      'device': 'الجهاز',
      'platform': 'المنصة',
      'setupComplete': 'اكتمل الإعداد!',
      'setupCompleteDesc': 'تم التحقق من هويتك وتسجيل جهازك بنجاح',
      'biometrics': 'البصمة',
      'enabled': 'مفعّل',
      'disabled': 'معطّل',
      'deviceRegistered': 'الجهاز المسجل',
      'goToHome': 'الذهاب للرئيسية',
    },
    'en': {
      // App
      'appName': 'Aqari',

      // Auth
      'welcomeBack': 'Welcome Back',
      'loginToAccount': 'Login to your account',
      'email': 'Email',
      'password': 'Password',
      'forgotPassword': 'Forgot Password?',
      'login': 'Login',
      'signUp': 'Sign Up',
      'orContinueWith': 'Or continue with',
      'or': 'or',
      'continueWithGoogle': 'Continue with Google',
      'googleSignInFailed': 'Google sign-in failed',
      'dontHaveAccount': "Don't have an account?",
      'alreadyHaveAccount': 'Already have an account?',
      'createAccount': 'Create New Account',
      'fullName': 'Full Name',
      'confirmPassword': 'Confirm Password',
      'phoneNumber': 'Phone Number',
      'resetPassword': 'Reset Password',
      'sendResetLink': 'Send Reset Link',
      'enterEmailToReset': 'Enter your email to reset your password',
      'backToLogin': 'Back to Login',
      'signInWithGoogle': 'Sign in with Google',
      'selectAccountType': 'Select Account Type',
      'selectAccountTypeSubtitle': 'Choose the option that best fits you',
      'fillYourDetails': 'Enter your details to continue',
      'landlord': 'Landlord',
      'tenant': 'Tenant',
      'lawyer': 'Lawyer',
      'user': 'User',
      'continueText': 'Continue',
      'agreeToTerms': 'By continuing, you agree to our',
      'termsOfService': 'Terms of Service',
      'and': 'and',
      'privacyPolicy': 'Privacy Policy',
      'emailSent': 'Email Sent',
      'checkInbox': 'Check your inbox to reset your password',

      // New Auth Strings
      'firstName': 'First Name',
      'lastName': 'Last Name',
      'identityNumber': 'Identity Number',
      'identityRequired': 'Identity number is required',
      'identityInvalid': 'Invalid identity number',
      'enterVerificationCode': 'Enter Verification Code',
      'verificationCodeSent': 'Verification code sent to your email',
      'newPassword': 'New Password',
      'enterNewPassword': 'Enter your new password',
      'sendVerificationCode': 'Send Verification Code',
      'verificationCode': 'Verification Code (6 digits)',
      'enterCode': 'Please enter verification code',
      'codeLength': 'Verification code must be 6 digits',
      'next': 'Next',
      'resendCode': "Didn't receive the code? Resend",
      'changePassword': 'Change Password',
      'passwordChanged': 'Password changed successfully',

      // Google Auth Role Selection
      'selectYourRole': 'Select Your Role',
      'selectRoleDescription': 'Please choose your role to continue creating your account',
      'landlordDescription': 'Manage properties, rentals, and contracts',
      'tenantDescription': 'Find properties and manage rental agreements',
      'lawyerDescription': 'Provide legal services and consultations',
      'userDescription': 'Browse properties and manage contracts',

      // User Types Descriptions
      'landlordDesc': 'Manage properties and contracts',
      'tenantDesc': 'Find and rent properties',
      'lawyerDesc': 'Manage cases and consultations',
      'userDesc': 'Browse properties and manage contracts',

      // OCR
      'scanIdCard': 'Scan ID Card',
      'scanFromCamera': 'Take Photo',
      'pickFromGallery': 'Choose from Gallery',
      'scanning': 'Scanning...',
      'idNumberExtracted': 'ID number extracted',
      'idNumberNotFound': 'ID number not found',
      'tryAgain': 'Try Again',
      'cancel': 'Cancel',

      // Home & Navigation
      'home': 'Home',
      'properties': 'Properties',
      'contracts': 'Contracts',
      'cases': 'Cases',
      'aiAssistant': 'AI Assistant',
      'settings': 'Settings',
      'logout': 'Logout',
      'welcomeToAqari': 'Welcome to Aqari',
      'managePropertiesEasily': 'Manage your properties easily',
      'quickActions': 'Quick Actions',
      'addProperty': 'Add Property',
      'newContract': 'New Contract',
      'damageInspection': 'Damage Inspection',
      'legalConsultation': 'Legal Consultation',
      'recentActivity': 'Recent Activity',
      'noRecentActivity': 'No recent activity',
      'notificationsWillAppear': 'Notifications and updates will appear here',

      // Property Actions
      'view': 'View',
      'edit': 'Edit',
      'delete': 'Delete',
      'myProperties': 'My Properties',
      'propertyDetails': 'Property Details',
      'location': 'Location',
      'noImageAvailable': 'No Image Available',
      'propertyDeleted': 'Property deleted',
      'deleteProperty': 'Delete Property',
      'deletePropertyConfirm': 'Are you sure you want to delete this property? This action cannot be undone.',
      'forSale': 'For Sale',
      'forRent': 'For Rent',
      'type': 'Type',
      'status': 'Status',
      'locationNotSet': 'Location not set',
      'latitude': 'Latitude',
      'longitude': 'Longitude',
      'openInGoogleMaps': 'Open in Google Maps',
      'propertyName': 'Property Name',
      'address': 'Address',
      'contractId': 'Contract ID',
      'documents': 'Documents',
      'registrationDocument': 'Registration Document',
      'uploaded': 'Uploaded',
      'created': 'Created',
      'updated': 'Updated',
      'editProperty': 'Edit Property',
      'propertyAddress': 'Property Address',
      'propertyType': 'Property Type',
      'propertyStatus': 'Property Status',
      'enterPropertyName': 'Enter property name',
      'enterPropertyAddress': 'Enter property address',
      'enterFullAddress': 'Enter full address',
      'propertyNameRequired': 'Property name is required',
      'propertyNameMinLength': 'Property name must be at least 3 characters',
      'propertyAddressRequired': 'Property address is required',
      'available': 'Available',
      'unavailable': 'Unavailable',
      'pending': 'Pending',
      'sold': 'Sold',
      'rented': 'Rented',
      'clear': 'Clear',
      'selectOnMap': 'Select on Map',
      'scan': 'Scan',
      'upload': 'Upload',
      'gallery': 'Gallery',
      'camera': 'Camera',
      'continue': 'Continue',
      'back': 'Back',
      'saveChanges': 'Save Changes',
      'createProperty': 'Create Property',
      'propertyCreatedSuccessfully': 'Property created successfully!',
      'discardChanges': 'Discard Changes?',
      'discard': 'Discard',
      'changeLocation': 'Change Location',
      'chooseFromGalleryTitle': 'Choose from Gallery',
      'selectMultiplePhotos': 'Select multiple photos',
      'takePhoto': 'Take Photo',
      'useCameraToCapture': 'Use camera to capture',
      'tapToChooseLocationVisually': 'Tap to choose location visually',
      'enterCoordinates': 'Enter Coordinates',
      'inputLatLngManually': 'Input latitude and longitude manually',
      'useCurrentLocation': 'Use Current Location',
      'autoDetectCurrentPosition': 'Auto-detect your current position',
      'estimateFromAddress': 'Estimate from Address',
      'findLocationUsingAddress': 'Find location using the address above',
      'confirmLocation': 'Confirm Location',
      'latitudeHint': 'Latitude (e.g., 36.8065)',
      'longitudeHint': 'Longitude (e.g., 10.1815)',
      'saveLocation': 'Save Location',
      'name': 'Name',
      'photos': 'Photos',
      'descriptionOptional': 'Description (Optional)',
      'addDetailedDescription': 'Add a detailed description...',
      'basicInformation': 'Basic Information',
      'enterBasicDetails': 'Enter basic details about the property',
      'propertyPhotos': 'Property Photos',
      'addPhotosToShowcase': 'Add photos to showcase your property',
      'mainPhoto': 'Main',
      'photosOptionalHint': 'You can add photos later from property details',
      'photosAdded': 'photos added',
      'propertyLocation': 'Property Location',
      'setExactLocation': 'Set the exact location of your property',
      'locationSet': 'Location Set',
      'selectOnMapTitle': 'Select on Map',
      'selectOnMapSubtitle': 'Tap to choose location visually',
      'tapOnMapOrDrag': 'Tap on map or drag the pin',
      'selectedCoordinates': 'Selected Coordinates',
      'openInGoogleMapsShort': 'Open in Google Maps',
      'enterCoordinatesTitle': 'Enter Coordinates',
      'locationOptionalHint': 'Location is optional, you can add it later',
      'notSet': 'Not set',
      'reviewAndCreate': 'Review & Create',
      'reviewPropertyDetails': 'Review your property details before creating',
      'propertySummary': 'Property Summary',
      'selectLocation': 'Select Location',
      'tapOnMapOrDragPin': 'Tap on map or drag the pin',

      // Theme
      'light': 'Light',
      'dark': 'Dark',
      'auto': 'Auto',

      // Validation
      'emailRequired': 'Email is required',
      'invalidEmail': 'Invalid email address',
      'passwordRequired': 'Password is required',
      'passwordTooShort': 'Password must be at least 6 characters',
      'nameRequired': 'Name is required',
      'phoneRequired': 'Phone number is required',
      'passwordsDoNotMatch': 'Passwords do not match',
      'accountTypeRequired': 'Please select an account type',

      // Language
      'language': 'Language',
      'arabic': 'العربية',
      'english': 'English',
      'french': 'Français',

      // Error Messages
      'noInternetConnection': 'No internet connection',
      'unexpectedError': 'An unexpected error occurred',
      'loginRequired': 'Login required',
      'invalidCredentials': 'Invalid credentials',
      'unauthorized': 'You are not authorized for this action',
      'notFound': 'Resource not found',
      'serverError': 'Server error, try again later',
      'emailAlreadyExists': 'Email already registered',
      'invalidCode': 'Invalid verification code',
      'codeExpired': 'Verification code expired',
      
      // Onboarding
      'verifyIdentity': 'Verify Your Identity',
      'verifyIdentityDesc': 'We need to verify your identity to secure your account and protect your transactions',
      'verifyIdentitySubtitle': 'ID Card, Biometrics & Device',
      'getStarted': 'Get Started',
      'scanCin': 'Scan ID Card',
      'scanCinDesc': 'Scan your national ID card to automatically extract your ID number',
      'ocrRequiresMobileApp': 'ID card scanning requires the mobile app',
      'useAppForOcr': 'Use the App to Scan',
      'uploadImage': 'Upload Image',
      'uploadCinImage': 'Upload your ID card image',
      'scanWithCamera': 'Scan with Camera',
      'takePhotoOfCin': 'Take a photo of your ID card',
      'chooseFromGallery': 'Choose from Gallery',
      'selectExistingPhoto': 'Select an existing photo',
      'enterManually': 'Enter Manually',
      'backToScan': 'Back to Scan',
      'cinNumber': 'ID Number',
      'cinDetected': 'ID Number Detected',
      'scanAgain': 'Scan Again',
      'verify': 'Verify',
      'setupBiometrics': 'Setup Biometrics',
      'setupBiometricsDesc': 'Use your fingerprint to login quickly and securely',
      'biometricsNotAvailableWeb': 'Biometrics not available on web. You can skip this step.',
      'enableBiometrics': 'Enable Biometrics',
      'biometricReason': 'Please verify your identity',
      'skipForNow': 'Skip for Now',
      'skip': 'Skip',
      'device': 'Device',
      'platform': 'Platform',
      'setupComplete': 'Setup Complete!',
      'setupCompleteDesc': 'Your identity has been verified and your device registered successfully',
      'biometrics': 'Biometrics',
      'enabled': 'Enabled',
      'disabled': 'Disabled',
      'deviceRegistered': 'Device Registered',
      'goToHome': 'Go to Home',
    },
    'fr': {
      // App
      'appName': 'Aqari',

      // Auth
      'welcomeBack': 'Bienvenue',
      'loginToAccount': 'Connectez-vous à votre compte',
      'email': 'E-mail',
      'password': 'Mot de passe',
      'forgotPassword': 'Mot de passe oublié?',
      'login': 'Connexion',
      'signUp': "S'inscrire",
      'orContinueWith': 'Ou continuer avec',
      'or': 'ou',
      'continueWithGoogle': 'Continuer avec Google',
      'googleSignInFailed': 'Échec de la connexion Google',
      'dontHaveAccount': "Vous n'avez pas de compte?",
      'alreadyHaveAccount': 'Vous avez déjà un compte?',
      'createAccount': 'Créer un nouveau compte',
      'fullName': 'Nom complet',
      'confirmPassword': 'Confirmer le mot de passe',
      'phoneNumber': 'Numéro de téléphone',
      'resetPassword': 'Réinitialiser le mot de passe',
      'sendResetLink': 'Envoyer le lien',
      'enterEmailToReset':
          'Entrez votre e-mail pour réinitialiser votre mot de passe',
      'backToLogin': 'Retour à la connexion',
      'signInWithGoogle': 'Se connecter avec Google',
      'selectAccountType': 'Sélectionnez le type de compte',
      'selectAccountTypeSubtitle': 'Choisissez l\'option qui vous convient',
      'fillYourDetails': 'Entrez vos informations pour continuer',
      'landlord': 'Propriétaire',
      'tenant': 'Locataire',
      'lawyer': 'Avocat',
      'user': 'Utilisateur',
      'continueText': 'Continuer',
      'agreeToTerms': 'En continuant, vous acceptez nos',
      'termsOfService': "Conditions d'utilisation",
      'and': 'et',
      'privacyPolicy': 'Politique de confidentialité',
      'emailSent': 'E-mail envoyé',
      'checkInbox':
          'Vérifiez votre boîte de réception pour réinitialiser votre mot de passe',

      // New Auth Strings
      'firstName': 'Prénom',
      'lastName': 'Nom de famille',
      'identityNumber': "Numéro d'identité",
      'identityRequired': "Le numéro d'identité est requis",
      'identityInvalid': "Numéro d'identité invalide",
      'enterVerificationCode': 'Entrez le code de vérification',
      'verificationCodeSent': 'Code de vérification envoyé à votre e-mail',
      'newPassword': 'Nouveau mot de passe',
      'enterNewPassword': 'Entrez votre nouveau mot de passe',
      'sendVerificationCode': 'Envoyer le code de vérification',
      'verificationCode': 'Code de vérification (6 chiffres)',
      'enterCode': 'Veuillez entrer le code de vérification',
      'codeLength': 'Le code de vérification doit comporter 6 chiffres',
      'next': 'Suivant',
      'resendCode': "Vous n'avez pas reçu le code? Renvoyer",
      'changePassword': 'Changer le mot de passe',
      'passwordChanged': 'Mot de passe changé avec succès',

      // Google Auth Role Selection
      'selectYourRole': 'Sélectionnez votre rôle',
      'selectRoleDescription': 'Veuillez choisir votre rôle pour continuer à créer votre compte',
      'landlordDescription': 'Gérer les propriétés, les locations et les contrats',
      'tenantDescription': 'Trouver des propriétés et gérer les contrats de location',
      'lawyerDescription': 'Fournir des services juridiques et des consultations',
      'userDescription': 'Parcourir les propriétés et gérer les contrats',

      // User Types Descriptions
      'landlordDesc': 'Gérer les propriétés et les contrats',
      'tenantDesc': 'Trouver et louer des propriétés',
      'lawyerDesc': 'Gérer les affaires et les consultations',
      'userDesc': 'Parcourir les propriétés et gérer les contrats',

      // OCR
      'scanIdCard': "Scanner la carte d'identité",
      'scanFromCamera': 'Prendre une photo',
      'pickFromGallery': 'Choisir dans la galerie',
      'scanning': 'Numérisation en cours...',
      'idNumberExtracted': "Numéro d'identité extrait",
      'idNumberNotFound': "Numéro d'identité non trouvé",
      'tryAgain': 'Réessayer',
      'cancel': 'Annuler',

      // Home & Navigation
      'home': 'Accueil',
      'properties': 'Propriétés',
      'contracts': 'Contrats',
      'cases': 'Affaires',
      'aiAssistant': 'Assistant IA',
      'settings': 'Paramètres',
      'logout': 'Déconnexion',
      'welcomeToAqari': 'Bienvenue sur Aqari',
      'managePropertiesEasily': 'Gérez vos propriétés facilement',
      'quickActions': 'Actions Rapides',
      'addProperty': 'Ajouter une propriété',
      'newContract': 'Nouveau contrat',
      'damageInspection': 'Inspection des dommages',
      'legalConsultation': 'Consultation juridique',
      'recentActivity': 'Activité récente',
      'noRecentActivity': "Aucune activité récente",
      'notificationsWillAppear':
          'Les notifications et mises à jour apparaîtront ici',

      // Property Actions
      'view': 'Voir',
      'edit': 'Modifier',
      'delete': 'Supprimer',
      'myProperties': 'Mes propriétés',
      'propertyDetails': 'Détails de la propriété',
      'location': 'Emplacement',
      'noImageAvailable': 'Aucune image disponible',
      'propertyDeleted': 'Propriété supprimée',
      'deleteProperty': 'Supprimer la propriété',
      'deletePropertyConfirm': 'Êtes-vous sûr de vouloir supprimer cette propriété? Cette action ne peut pas être annulée.',
      'forSale': 'À vendre',
      'forRent': 'À louer',
      'type': 'Type',
      'status': 'Statut',
      'locationNotSet': 'Emplacement non défini',
      'latitude': 'Latitude',
      'longitude': 'Longitude',
      'openInGoogleMaps': 'Ouvrir dans Google Maps',
      'propertyName': 'Nom de la propriété',
      'address': 'Adresse',
      'contractId': 'ID du contrat',
      'documents': 'Documents',
      'registrationDocument': "Document d'enregistrement",
      'uploaded': 'Téléchargé',
      'created': 'Créé',
      'updated': 'Mis à jour',
      'editProperty': 'Modifier la propriété',
      'propertyAddress': 'Adresse de la propriété',
      'propertyType': 'Type de propriété',
      'propertyStatus': 'Statut de la propriété',
      'enterPropertyName': 'Entrez le nom de la propriété',
      'enterPropertyAddress': 'Entrez l\'adresse de la propriété',
      'enterFullAddress': 'Entrez l\'adresse complète',
      'propertyNameRequired': 'Le nom de la propriété est requis',
      'propertyNameMinLength': 'Le nom de la propriété doit contenir au moins 3 caractères',
      'propertyAddressRequired': 'L\'adresse de la propriété est requise',
      'available': 'Disponible',
      'unavailable': 'Indisponible',
      'pending': 'En attente',
      'sold': 'Vendu',
      'rented': 'Loué',
      'clear': 'Effacer',
      'selectOnMap': 'Sélectionner sur la carte',
      'scan': 'Scanner',
      'upload': 'Télécharger',
      'gallery': 'Galerie',
      'camera': 'Caméra',
      'continue': 'Continuer',
      'saveChanges': 'Enregistrer les modifications',
      'createProperty': 'Créer une propriété',
      'propertyCreatedSuccessfully': 'Propriété créée avec succès!',
      'discardChanges': 'Abandonner les modifications?',
      'discard': 'Abandonner',
      'changeLocation': 'Changer l\'emplacement',
      'chooseFromGalleryTitle': 'Choisir dans la galerie',
      'selectMultiplePhotos': 'Sélectionner plusieurs photos',
      'takePhoto': 'Prendre une photo',
      'useCameraToCapture': 'Utiliser la caméra pour capturer',
      'tapToChooseLocationVisually': 'Appuyez pour choisir l\'emplacement visuellement',
      'enterCoordinates': 'Entrer les coordonnées',
      'inputLatLngManually': 'Entrer manuellement la latitude et la longitude',
      'useCurrentLocation': 'Utiliser l\'emplacement actuel',
      'autoDetectCurrentPosition': 'Détecter automatiquement votre position actuelle',
      'estimateFromAddress': 'Estimer depuis l\'adresse',
      'findLocationUsingAddress': 'Trouver l\'emplacement en utilisant l\'adresse ci-dessus',
      'confirmLocation': 'Confirmer l\'emplacement',
      'latitudeHint': 'Latitude (ex: 36.8065)',
      'longitudeHint': 'Longitude (ex: 10.1815)',
      'saveLocation': 'Enregistrer l\'emplacement',
      'name': 'Nom',
      'photos': 'Photos',
      'descriptionOptional': 'Description (Optionnel)',
      'addDetailedDescription': 'Ajouter une description détaillée...',
      'basicInformation': 'Informations de base',
      'enterBasicDetails': 'Entrez les détails de base de la propriété',
      'propertyPhotos': 'Photos de la propriété',
      'addPhotosToShowcase': 'Ajoutez des photos pour présenter votre propriété',
      'mainPhoto': 'Principale',
      'photosOptionalHint': 'Vous pouvez ajouter des photos plus tard depuis les détails',
      'photosAdded': 'photos ajoutées',
      'propertyLocation': 'Emplacement de la propriété',
      'setExactLocation': 'Définir l\'emplacement exact de votre propriété',
      'locationSet': 'Emplacement défini',
      'selectOnMapTitle': 'Sélectionner sur la carte',
      'selectOnMapSubtitle': 'Appuyez pour choisir l\'emplacement visuellement',
      'tapOnMapOrDrag': 'Appuyez sur la carte ou faites glisser l\'épingle',
      'selectedCoordinates': 'Coordonnées sélectionnées',
      'openInGoogleMapsShort': 'Ouvrir dans Google Maps',
      'enterCoordinatesTitle': 'Entrer les coordonnées',
      'locationOptionalHint': 'L\'emplacement est facultatif, vous pouvez l\'ajouter plus tard',
      'notSet': 'Non défini',
      'reviewAndCreate': 'Réviser et créer',
      'reviewPropertyDetails': 'Vérifiez les détails avant de créer',
      'propertySummary': 'Résumé de la propriété',
      'selectLocation': 'Sélectionner l\'emplacement',
      'tapOnMapOrDragPin': 'Appuyez sur la carte ou faites glisser l\'épingle',

      // Theme
      'light': 'Clair',
      'dark': 'Sombre',
      'auto': 'Auto',

      // Validation
      'emailRequired': "L'e-mail est requis",
      'invalidEmail': 'Adresse e-mail invalide',
      'passwordRequired': 'Le mot de passe est requis',
      'passwordTooShort':
          'Le mot de passe doit comporter au moins 6 caractères',
      'nameRequired': 'Le nom est requis',
      'phoneRequired': 'Le numéro de téléphone est requis',
      'passwordsDoNotMatch': 'Les mots de passe ne correspondent pas',
      'accountTypeRequired': 'Veuillez sélectionner un type de compte',

      // Language
      'language': 'Langue',
      'arabic': 'العربية',
      'english': 'English',
      'french': 'Français',

      // Error Messages
      'noInternetConnection': 'Pas de connexion Internet',
      'unexpectedError': 'Une erreur inattendue s\'est produite',
      'loginRequired': 'Connexion requise',
      'invalidCredentials': 'Identifiants invalides',
      'unauthorized': 'Vous n\'\u00eates pas autoris\u00e9 pour cette action',
      'notFound': 'Ressource non trouv\u00e9e',
      'serverError': 'Erreur serveur, r\u00e9essayez plus tard',
      'emailAlreadyExists': 'E-mail d\u00e9j\u00e0 enregistr\u00e9',
      'invalidCode': 'Code de v\u00e9rification invalide',
      'codeExpired': 'Code de v\u00e9rification expir\u00e9',
      
      // Onboarding
      'verifyIdentity': 'Vérifier votre identité',
      'verifyIdentityDesc': 'Nous devons vérifier votre identité pour sécuriser votre compte et protéger vos transactions',
      'verifyIdentitySubtitle': "Carte d'identité, biométrie et appareil",
      'getStarted': 'Commencer',
      'scanCin': "Scanner la carte d'identité",
      'scanCinDesc': "Scannez votre carte d'identité nationale pour extraire automatiquement votre numéro",
      'ocrRequiresMobileApp': "Le scan de la carte d'identité nécessite l'application mobile",
      'useAppForOcr': "Utilisez l'application pour scanner",
      'uploadImage': 'Télécharger une image',
      'uploadCinImage': "Téléchargez l'image de votre carte d'identité",
      'scanWithCamera': 'Scanner avec la caméra',
      'takePhotoOfCin': "Prenez une photo de votre carte d'identité",
      'chooseFromGallery': 'Choisir dans la galerie',
      'selectExistingPhoto': 'Sélectionnez une photo existante',
      'enterManually': 'Saisir manuellement',
      'backToScan': 'Retour au scan',
      'cinNumber': "Numéro d'identité",
      'cinDetected': "Numéro d'identité détecté",
      'scanAgain': 'Scanner à nouveau',
      'verify': 'Vérifier',
      'setupBiometrics': 'Configurer la biométrie',
      'setupBiometricsDesc': 'Utilisez votre empreinte digitale pour vous connecter rapidement et en toute sécurité',
      'biometricsNotAvailableWeb': 'La biométrie n\'est pas disponible sur le web. Vous pouvez ignorer cette étape.',
      'enableBiometrics': 'Activer la biométrie',
      'biometricReason': 'Veuillez vérifier votre identité',
      'skipForNow': 'Ignorer pour le moment',
      'skip': 'Ignorer',
      'device': 'Appareil',
      'platform': 'Plateforme',
      'setupComplete': 'Configuration terminée!',
      'setupCompleteDesc': 'Votre identité a été vérifiée et votre appareil enregistré avec succès',
      'biometrics': 'Biométrie',
      'enabled': 'Activé',
      'disabled': 'Désactivé',
      'deviceRegistered': 'Appareil enregistré',
      'goToHome': "Aller à l'accueil",
      'back': 'Retour',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Getters for commonly used strings
  String get appName => translate('appName');
  String get welcomeBack => translate('welcomeBack');
  String get loginToAccount => translate('loginToAccount');
  String get email => translate('email');
  String get password => translate('password');
  String get forgotPassword => translate('forgotPassword');
  String get login => translate('login');
  String get signUp => translate('signUp');
  String get orContinueWith => translate('orContinueWith');
  String get dontHaveAccount => translate('dontHaveAccount');
  String get alreadyHaveAccount => translate('alreadyHaveAccount');
  String get createAccount => translate('createAccount');
  String get fullName => translate('fullName');
  String get confirmPassword => translate('confirmPassword');
  String get phoneNumber => translate('phoneNumber');
  String get resetPassword => translate('resetPassword');
  String get sendResetLink => translate('sendResetLink');
  String get enterEmailToReset => translate('enterEmailToReset');
  String get backToLogin => translate('backToLogin');
  String get signInWithGoogle => translate('signInWithGoogle');
  String get selectAccountType => translate('selectAccountType');
  String get selectAccountTypeSubtitle =>
      translate('selectAccountTypeSubtitle');
  String get fillYourDetails => translate('fillYourDetails');
  String get landlord => translate('landlord');
  String get tenant => translate('tenant');
  String get lawyer => translate('lawyer');
  String get continueText => translate('continueText');
  String get agreeToTerms => translate('agreeToTerms');
  String get termsOfService => translate('termsOfService');
  String get and => translate('and');
  String get privacyPolicy => translate('privacyPolicy');
  String get emailSent => translate('emailSent');
  String get checkInbox => translate('checkInbox');
  String get emailRequired => translate('emailRequired');
  String get invalidEmail => translate('invalidEmail');
  String get passwordRequired => translate('passwordRequired');
  String get passwordTooShort => translate('passwordTooShort');
  String get nameRequired => translate('nameRequired');
  String get phoneRequired => translate('phoneRequired');
  String get passwordsDoNotMatch => translate('passwordsDoNotMatch');
  String get accountTypeRequired => translate('accountTypeRequired');
  String get language => translate('language');
  String get arabic => translate('arabic');
  String get english => translate('english');
  String get french => translate('french');

  // New Auth Getters
  String get firstName => translate('firstName');
  String get lastName => translate('lastName');
  String get identityNumber => translate('identityNumber');
  String get identityRequired => translate('identityRequired');
  String get identityInvalid => translate('identityInvalid');
  String get enterVerificationCode => translate('enterVerificationCode');
  String get verificationCodeSent => translate('verificationCodeSent');
  String get newPassword => translate('newPassword');
  String get enterNewPassword => translate('enterNewPassword');
  String get sendVerificationCode => translate('sendVerificationCode');
  String get verificationCode => translate('verificationCode');
  String get enterCode => translate('enterCode');
  String get codeLength => translate('codeLength');
  String get next => translate('next');
  String get resendCode => translate('resendCode');
  String get changePassword => translate('changePassword');
  String get passwordChanged => translate('passwordChanged');

  // User Types Descriptions
  String get landlordDesc => translate('landlordDesc');
  String get tenantDesc => translate('tenantDesc');
  String get lawyerDesc => translate('lawyerDesc');

  // OCR Getters
  String get scanIdCard => translate('scanIdCard');
  String get scanFromCamera => translate('scanFromCamera');
  String get pickFromGallery => translate('pickFromGallery');
  String get scanning => translate('scanning');
  String get idNumberExtracted => translate('idNumberExtracted');
  String get idNumberNotFound => translate('idNumberNotFound');
  String get tryAgain => translate('tryAgain');
  String get cancel => translate('cancel');

  // Home & Navigation Getters
  String get home => translate('home');
  String get properties => translate('properties');
  String get contracts => translate('contracts');
  String get cases => translate('cases');
  String get aiAssistant => translate('aiAssistant');
  String get settings => translate('settings');
  String get logout => translate('logout');
  String get welcomeToAqari => translate('welcomeToAqari');
  String get managePropertiesEasily => translate('managePropertiesEasily');
  String get quickActions => translate('quickActions');
  String get addProperty => translate('addProperty');
  String get newContract => translate('newContract');
  String get damageInspection => translate('damageInspection');
  String get legalConsultation => translate('legalConsultation');
  String get recentActivity => translate('recentActivity');
  String get noRecentActivity => translate('noRecentActivity');
  String get notificationsWillAppear => translate('notificationsWillAppear');

  // Theme Getters
  String get light => translate('light');
  String get dark => translate('dark');
  String get auto => translate('auto');

  // Error Message Getters
  String get noInternetConnection => translate('noInternetConnection');
  String get unexpectedError => translate('unexpectedError');
  String get loginRequired => translate('loginRequired');
  String get invalidCredentials => translate('invalidCredentials');
  String get unauthorized => translate('unauthorized');
  String get notFound => translate('notFound');
  String get serverError => translate('serverError');
  String get emailAlreadyExists => translate('emailAlreadyExists');
  String get invalidCode => translate('invalidCode');
  String get codeExpired => translate('codeExpired');
  
  // Onboarding Getters
  String get verifyIdentity => translate('verifyIdentity');
  String get verifyIdentityDesc => translate('verifyIdentityDesc');
  String get verifyIdentitySubtitle => translate('verifyIdentitySubtitle');
  String get getStarted => translate('getStarted');
  String get scanCin => translate('scanCin');
  String get scanCinDesc => translate('scanCinDesc');
  String get scanWithCamera => translate('scanWithCamera');
  String get takePhotoOfCin => translate('takePhotoOfCin');
  String get chooseFromGallery => translate('chooseFromGallery');
  String get selectExistingPhoto => translate('selectExistingPhoto');
  String get enterManually => translate('enterManually');
  String get backToScan => translate('backToScan');
  String get cinNumber => translate('cinNumber');
  String get cinDetected => translate('cinDetected');
  String get scanAgain => translate('scanAgain');
  String get verify => translate('verify');
  String get setupBiometrics => translate('setupBiometrics');
  String get setupBiometricsDesc => translate('setupBiometricsDesc');
  String get biometricsNotAvailableWeb => translate('biometricsNotAvailableWeb');
  String get enableBiometrics => translate('enableBiometrics');
  String get biometricReason => translate('biometricReason');
  String get skipForNow => translate('skipForNow');
  String get skip => translate('skip');
  String get device => translate('device');
  String get platform => translate('platform');
  String get setupComplete => translate('setupComplete');
  String get setupCompleteDesc => translate('setupCompleteDesc');
  String get biometrics => translate('biometrics');
  String get enabled => translate('enabled');
  String get disabled => translate('disabled');
  String get deviceRegistered => translate('deviceRegistered');
  String get goToHome => translate('goToHome');
  String get back => translate('back');

  // Property Actions Getters
  String get view => translate('view');
  String get edit => translate('edit');
  String get delete => translate('delete');
  String get myProperties => translate('myProperties');
  String get propertyDetails => translate('propertyDetails');
  String get location => translate('location');
  String get noImageAvailable => translate('noImageAvailable');
  String get propertyDeleted => translate('propertyDeleted');
  String get deleteProperty => translate('deleteProperty');
  String get deletePropertyConfirm => translate('deletePropertyConfirm');
  String get forSale => translate('forSale');
  String get forRent => translate('forRent');
  String get type => translate('type');
  String get status => translate('status');
  String get locationNotSet => translate('locationNotSet');
  String get latitude => translate('latitude');
  String get longitude => translate('longitude');
  String get openInGoogleMaps => translate('openInGoogleMaps');
  String get propertyName => translate('propertyName');
  String get address => translate('address');
  String get contractId => translate('contractId');
  String get documents => translate('documents');
  String get registrationDocument => translate('registrationDocument');
  String get uploaded => translate('uploaded');
  String get created => translate('created');
  String get updated => translate('updated');
  String get editProperty => translate('editProperty');
  String get propertyAddress => translate('propertyAddress');
  String get propertyType => translate('propertyType');
  String get propertyStatus => translate('propertyStatus');
  String get enterPropertyName => translate('enterPropertyName');
  String get enterPropertyAddress => translate('enterPropertyAddress');
  String get enterFullAddress => translate('enterFullAddress');
  String get propertyNameRequired => translate('propertyNameRequired');
  String get propertyNameMinLength => translate('propertyNameMinLength');
  String get propertyAddressRequired => translate('propertyAddressRequired');
  String get available => translate('available');
  String get unavailable => translate('unavailable');
  String get pending => translate('pending');
  String get sold => translate('sold');
  String get rented => translate('rented');
  String get clear => translate('clear');
  String get selectOnMap => translate('selectOnMap');
  String get scan => translate('scan');
  String get upload => translate('upload');
  String get gallery => translate('gallery');
  String get camera => translate('camera');
  String get saveChanges => translate('saveChanges');
  String get createProperty => translate('createProperty');
  String get propertyCreatedSuccessfully => translate('propertyCreatedSuccessfully');
  String get discardChanges => translate('discardChanges');
  String get discard => translate('discard');
  String get changeLocation => translate('changeLocation');
  String get chooseFromGalleryTitle => translate('chooseFromGalleryTitle');
  String get selectMultiplePhotos => translate('selectMultiplePhotos');
  String get takePhoto => translate('takePhoto');
  String get useCameraToCapture => translate('useCameraToCapture');
  String get tapToChooseLocationVisually => translate('tapToChooseLocationVisually');
  String get enterCoordinates => translate('enterCoordinates');
  String get inputLatLngManually => translate('inputLatLngManually');
  String get useCurrentLocation => translate('useCurrentLocation');
  String get autoDetectCurrentPosition => translate('autoDetectCurrentPosition');
  String get estimateFromAddress => translate('estimateFromAddress');
  String get findLocationUsingAddress => translate('findLocationUsingAddress');
  String get confirmLocation => translate('confirmLocation');
  String get latitudeHint => translate('latitudeHint');
  String get longitudeHint => translate('longitudeHint');
  String get saveLocation => translate('saveLocation');
  String get name => translate('name');
  String get photos => translate('photos');
  String get descriptionOptional => translate('descriptionOptional');
  String get addDetailedDescription => translate('addDetailedDescription');
  String get basicInformation => translate('basicInformation');
  String get enterBasicDetails => translate('enterBasicDetails');
  String get propertyPhotos => translate('propertyPhotos');
  String get addPhotosToShowcase => translate('addPhotosToShowcase');
  String get mainPhoto => translate('mainPhoto');
  String get photosOptionalHint => translate('photosOptionalHint');
  String get photosAdded => translate('photosAdded');
  String get propertyLocation => translate('propertyLocation');
  String get setExactLocation => translate('setExactLocation');
  String get locationSet => translate('locationSet');
  String get selectOnMapTitle => translate('selectOnMapTitle');
  String get selectOnMapSubtitle => translate('selectOnMapSubtitle');
  String get tapOnMapOrDrag => translate('tapOnMapOrDrag');
  String get selectedCoordinates => translate('selectedCoordinates');
  String get openInGoogleMapsShort => translate('openInGoogleMapsShort');
  String get enterCoordinatesTitle => translate('enterCoordinatesTitle');
  String get locationOptionalHint => translate('locationOptionalHint');
  String get notSet => translate('notSet');
  String get reviewAndCreate => translate('reviewAndCreate');
  String get reviewPropertyDetails => translate('reviewPropertyDetails');
  String get propertySummary => translate('propertySummary');
  String get selectLocation => translate('selectLocation');
  String get tapOnMapOrDragPin => translate('tapOnMapOrDragPin');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['ar', 'en', 'fr'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
