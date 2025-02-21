enum CardLanguage {
  english('English', 'en'),
  japanese('Japanese', 'jp');

  final String displayName;
  final String code;
  
  const CardLanguage(this.displayName, this.code);
}
