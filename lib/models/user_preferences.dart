class UserPreferences {
  final bool isDarkMode;
  final String defaultCardTemplate;
  final bool autoSaveContacts;

  UserPreferences({
    this.isDarkMode = false,
    this.defaultCardTemplate = 'default',
    this.autoSaveContacts = true,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
        isDarkMode: json['isDarkMode'] ?? false,
        defaultCardTemplate: json['defaultCardTemplate'] ?? 'default',
        autoSaveContacts: json['autoSaveContacts'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'isDarkMode': isDarkMode,
        'defaultCardTemplate': defaultCardTemplate,
        'autoSaveContacts': autoSaveContacts,
      };
}
