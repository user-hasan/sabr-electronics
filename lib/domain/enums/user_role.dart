/// رتب وأدوار المستخدمين والصلاحيات (RBAC)
enum UserRole {
  owner('owner', 'صاحب المركز / المدير العام'),
  reception('reception', 'كاونتر الاستقبال'),
  technician('technician', 'مهندس / فني الصيانة');

  final String code;
  final String label;

  const UserRole(this.code, this.label);

  static UserRole fromCode(String code) {
    return UserRole.values.firstWhere(
      (r) => r.code.toLowerCase() == code.toLowerCase(),
      orElse: () => UserRole.technician,
    );
  }
}
