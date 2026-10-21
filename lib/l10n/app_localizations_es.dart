// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Alacena Bunker';

  @override
  String get splashBrandName => 'ALACENA BUNKER';

  @override
  String get tabActive => 'Activos';

  @override
  String get tabExpired => 'Caducados';

  @override
  String get sortByName => 'Ordenar por nombre';

  @override
  String get sortByExpiry => 'Ordenar por caducidad';

  @override
  String get emptyActive =>
      'Aún no hay artículos activos. Añade alimentos con el botón +.';

  @override
  String get emptyExpired => 'No hay artículos caducados.';

  @override
  String get emptySoon => 'Nada por caducar en los próximos días.';

  @override
  String get filterOptimal => 'Óptimo';

  @override
  String get filterSoon => 'Por caducar';

  @override
  String get filterExpired => 'Caducado';

  @override
  String productsCount(int count) {
    return '$count productos';
  }

  @override
  String get onboardingWelcome => 'Bienvenid@ a Alacena Bunker';

  @override
  String get onboardingTagline =>
      'Tu bunker de alimentos para cualquier situación';

  @override
  String get onboardingStart => 'Iniciar';

  @override
  String get tabHome => 'Inicio';

  @override
  String get navAdd => 'Añadir';

  @override
  String get addItem => 'Añadir artículo';

  @override
  String get editItem => 'Editar artículo';

  @override
  String get fieldName => 'Nombre';

  @override
  String get fieldQuantity => 'Cantidad';

  @override
  String get fieldUnit => 'Unidad';

  @override
  String get fieldCategory => 'Categoría';

  @override
  String get fieldNotes => 'Notas';

  @override
  String get fieldLocation => 'Ubicación';

  @override
  String get fieldExpiry => 'Caducidad';

  @override
  String get precisionDay => 'Día / Mes / Año';

  @override
  String get precisionMonth => 'Mes / Año';

  @override
  String get save => 'Guardar';

  @override
  String get delete => 'Borrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirmDeleteTitle => '¿Borrar artículo?';

  @override
  String get confirmDeleteMessage => 'Se eliminará del inventario.';

  @override
  String get errorNameEmpty => 'Escribe un nombre.';

  @override
  String get errorQuantityNotPositive => 'La cantidad debe ser mayor que cero.';

  @override
  String get errorExpiryIncomplete => 'Indica la caducidad.';

  @override
  String get errorExpiryInvalid => 'La caducidad no es válida.';

  @override
  String get unitPz => 'pz';

  @override
  String get unitKg => 'kg';

  @override
  String get unitG => 'g';

  @override
  String get unitL => 'L';

  @override
  String get unitMl => 'ml';

  @override
  String get categoryDairy => 'Lácteos';

  @override
  String get categoryMeat => 'Carne';

  @override
  String get categoryVegetables => 'Verdura';

  @override
  String get categoryPantry => 'Despensa';

  @override
  String get categoryOther => 'Otro';

  @override
  String get locationFridge => 'Nevera';

  @override
  String get locationPantry => 'Despensa';

  @override
  String get locationOther => 'Otro';

  @override
  String get pickDate => 'Elegir fecha';

  @override
  String get pickMonth => 'Elegir mes';

  @override
  String get sectionIdentity => 'Artículo';

  @override
  String get sectionExpiry => 'Caducidad';

  @override
  String get sectionQuantity => 'Cantidad';

  @override
  String get sectionDetails => 'Detalles';

  @override
  String get urgencyExpired => 'Caducado';

  @override
  String get urgencySoon => 'Por caducar';

  @override
  String get urgencyOk => 'Óptimo';

  @override
  String get emptyActiveHint => 'Pulsa + para registrar el primero.';

  @override
  String get splashTagline => 'Tu bunker de alimentos para cualquier situación';

  @override
  String get reminderChannelName => 'Avisos de caducidad';

  @override
  String get reminderChannelDescription =>
      'Avisos antes de que caduquen tus alimentos';

  @override
  String get reminderWhenToday => 'hoy';

  @override
  String get reminderWhenTomorrow => 'mañana';

  @override
  String reminderWhenOn(String date) {
    return 'el $date';
  }

  @override
  String reminderWhenInMonth(String month) {
    return 'en $month';
  }

  @override
  String reminderItemExpires(String name, String when) {
    return '$name caduca $when';
  }

  @override
  String reminderGroupTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos por caducar',
      one: '1 artículo por caducar',
    );
    return '$_temp0';
  }

  @override
  String get reminderSettingsTitle => 'Recordatorios';

  @override
  String get reminderEnabled => 'Avisos de caducidad';

  @override
  String get reminderEnabledHint =>
      'Te avisamos antes de que caduque un alimento';

  @override
  String get reminderGeneralLead => 'Avisarme';

  @override
  String get reminderNotifyAt => 'Hora del aviso';

  @override
  String get reminderByCategory => 'Por categoría';

  @override
  String get reminderByCategoryHint =>
      'Cambia con cuánta antelación avisa cada categoría o desactívala.';

  @override
  String get reminderLeadSameDay => 'El mismo día que caduca';

  @override
  String reminderLeadDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days días antes',
      one: '1 día antes',
    );
    return '$_temp0';
  }

  @override
  String reminderRuleGeneral(String lead) {
    return 'Como la general ($lead)';
  }

  @override
  String get reminderRuleOff => 'Sin aviso';

  @override
  String get reminderPermissionDenied =>
      'Las notificaciones de Alacena Bunker están desactivadas, así que los avisos no llegarán.';

  @override
  String get reminderOpenSettings => 'Activar en ajustes';

  @override
  String get scanTitle => 'Escanear producto';

  @override
  String get scanRegisterManual => 'Registrar manual';

  @override
  String get scanLookingUp => 'Buscando producto…';

  @override
  String get scanCameraDeniedTitle => 'Sin acceso a la cámara';

  @override
  String get scanCameraDeniedBody =>
      'Activa el permiso de cámara o registra el producto a mano.';

  @override
  String get scanNotFound =>
      'No encontramos ese producto. Puedes registrarlo a mano.';

  @override
  String get scanNetworkError =>
      'No hay internet o la búsqueda no responde. Puedes registrarlo a mano.';

  @override
  String get scanConfirmTitle => 'Confirmar producto';

  @override
  String get scanSave => 'Guardar en inventario';

  @override
  String get productImageOpen => 'Ver foto';

  @override
  String get productImageAdd => 'Añadir foto';

  @override
  String get productImageCamera => 'Cámara';

  @override
  String get productImageGallery => 'Galería';

  @override
  String get productImageReplace => 'Cambiar foto';

  @override
  String get productImageRemove => 'Quitar foto';

  @override
  String get productImagePermissionDenied =>
      'Sin permiso para la foto. Puedes guardar el artículo sin imagen.';
}
