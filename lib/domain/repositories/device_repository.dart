import '../entities/device_entity.dart';
import '../enums/device_category.dart';

abstract class DeviceRepository {
  Future<List<DeviceEntity>> getDevicesByCustomerId(int customerId);
  Future<DeviceEntity?> getDeviceById(int id);
  Future<List<DeviceEntity>> getDevicesByCategory(DeviceCategory category);
  Future<List<DeviceEntity>> searchDevices(String query);
  Future<int> createDevice(DeviceEntity device);
  Future<bool> updateDevice(DeviceEntity device);
  Future<bool> deleteDevice(int id);
  Future<int> getDeviceCount();
}
