Kozağ: Hastane Entegreli Gebe Takip Otomasyon Sistemi
Kozağ, standart ve izole gebe takip uygulamalarından farklı olarak, doğrudan bir Hastane Bilgi Yönetim Sistemi (HBYS) entegrasyonu vizyonuyla kurgulanmış bir mobil otomasyon projesidir. Sistem, veri doğruluğunu ve klinik güvenliği merkeze alarak geliştirilmiş, güçlü bir yerel veritabanı ve otomasyon mimarisi üzerine inşa edilmiştir.

Öne Çıkan Arka Plan (Backend) ve Mimari Özellikler
Güvenli ve İzole Kayıt Mekanizması: Uygulama, son kullanıcı (anne) kaydına kapalıdır. Kayıt işlemleri sadece yetkili sağlık personeli (Admin) tarafından tıbbi verilerle yapılır.

İlişkisel Veritabanı Yönetimi (SQLite): users, children ve daily_logs tabloları arasında Foreign Key ilişkileriyle yapılandırılmış, veri tutarsızlığını engelleyen sağlam bir veritabanı şeması.

Singleton Tasarım Deseni: Veritabanı bağlantı sızıntılarını (memory leak) önlemek ve performansı optimize etmek için Singleton mimarisi kullanılmıştır.

Zaman Çıpası (Time Anchor) Algoritması: Hastane kayıt anını (registration_date) baz alarak aradan geçen süreyi hesaplayan ve gebelik haftasını, bebek gelişimini ve tıbbi uyarıları hiçbir manuel veriye ihtiyaç duymadan otomatik olarak güncelleyen matematiksel motor.

Kronolojik Sıfırlama Mekanizması: Gece yarısı (00:00) geçişlerini cihazın tarih damgasıyla (YYYY-MM-DD) yakalayıp, geçmiş verileri ezmeden yeni bir günlük kayıt satırı (su, diyet, egzersiz planı) açan asenkron kontrol yapısı.

Gelecek Vizyonu (AI & Veri Entegrasyonları)
Bu proje, bir sonraki aşamada tamamen yapay zeka ve arka plan veri entegrasyonlarıyla genişletilmek üzere modüler bir altyapıda tasarlanmıştır:

LLM Tabanlı Dinamik Beslenme Motoru: Hastane veri girişinden gelen güncel kan değerleri (demir, şeker vb.), kilo ve gebelik haftası parametrelerinin (prompt context) bir Yapay Zeka modeline beslenerek anneye özel, günlük dinamik kalori ve menü hesaplamalarının yapılması.

Medikal Veri API Entegrasyonları: Uluslararası tıp veritabanlarından veya Sağlık Bakanlığı servislerinden anlık, doğrulanmış medikal haberlerin REST API aracılığıyla uygulamaya çekilmesi.

Kurulum ve Çalıştırma
Projeyi kendi bilgisayarınızda derlemek ve incelemek için aşağıdaki adımları izleyebilirsiniz:

Depoyu bilgisayarınıza klonlayın:

Bash
git clone https://github.com/Muhammedd-18/Koza-.git
2. Gerekli Flutter paketlerini yükleyin:
   ```bash
   flutter pub get
Geçici derleme dosyalarını temizleyin (İsteğe bağlı):

flutter clean

4. Projeyi derleyin ve emülatörde çalıştırın:
   ```bash
flutter run
👨‍💻 Geliştirici Bilgileri
Geliştirici: Muhammed Nuri Çelik

Eğitim: İstanbul Topkapı Üniversitesi, Bilgisayar Mühendisliği
