import 'package:get_it/get_it.dart';
import 'package:halalbite_app/core/services/location_service.dart';


GetIt locator = GetIt.instance;
setupLocator() {
  locator.registerSingleton(LocationService());
}
