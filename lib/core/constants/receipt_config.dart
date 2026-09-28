class ReceiptConfig {
  static String storeName = 'Kasir Pintar';
  static String storeAddress = 'Jl. Contoh No. 123, Jakarta';
  static String storePhone = '08xx-xxxx-xxxx';
  static String footerText = 'Terima kasih telah berbelanja';
  static String taxInfo = '';
  
  static void update({
    String? name,
    String? address,
    String? phone,
    String? footer,
    String? tax,
  }) {
    if (name != null) storeName = name;
    if (address != null) storeAddress = address;
    if (phone != null) storePhone = phone;
    if (footer != null) footerText = footer;
    if (tax != null) taxInfo = tax;
  }
}