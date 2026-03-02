class AppSettings {
  final String currencyCode;
  final String currencySymbol;

  const AppSettings({required this.currencyCode, required this.currencySymbol});

  static const defaults = AppSettings(currencyCode: 'GBP', currencySymbol: '£');
}
