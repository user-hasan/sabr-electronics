import '../entities/customer_entity.dart';

abstract class CustomerRepository {
  Future<List<CustomerEntity>> getAllCustomers({int limit = 50, int offset = 0});
  Future<CustomerEntity?> getCustomerById(int id);
  Future<CustomerEntity?> getCustomerByPhone(String phone);
  Future<List<CustomerEntity>> searchCustomers(String query);
  Future<int> createCustomer(CustomerEntity customer);
  Future<bool> updateCustomer(CustomerEntity customer);
  Future<bool> deleteCustomer(int id);
  Future<int> getCustomerCount();
  Future<Map<String, dynamic>> getCustomerStats(int customerId);
}
