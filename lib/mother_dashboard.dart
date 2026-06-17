import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'database_helper.dart';
import 'login_screen.dart';

class MotherDashboard extends StatefulWidget {
  final Map<String, dynamic> user;
  const MotherDashboard({super.key, required this.user});

  @override
  State<MotherDashboard> createState() => _MotherDashboardState();
}

class _MotherDashboardState extends State<MotherDashboard> {
  int _currentIndex = 0;
  bool _isLoading = true;

  double _waterDrank = 0.0;
  final double _waterTarget = 2.5;
  int _loveCount = 0;
  int _calculatedCurrentWeek = 0;

  late List<Map<String, dynamic>> _todayDiet;
  late List<Map<String, dynamic>> _todayExercises;

  final List<Widget> _hearts = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _calculateDynamicWeek();
    _loadDailyDataFromDB();
  }

  void _calculateDynamicWeek() {
    int baseWeek = widget.user['pregnancy_week'] ?? 0;

    String regDateStr = widget.user['registration_date'] ?? DateTime.now().toIso8601String();
    DateTime regDate = DateTime.parse(regDateStr);
    int daysPassed = DateTime.now().difference(regDate).inDays;
    int weeksPassed = daysPassed ~/ 7;
    int currentWeek = baseWeek + weeksPassed;
    if (currentWeek > 40) currentWeek = 40;

    _calculatedCurrentWeek = currentWeek;
  }

  Map<String, String> _getBabyInfo(int week) {
    if (week < 4) return {'fruit': 'Mucizevi Tohum', 'desc': 'Bebeğiniz henüz minicik bir hücre topluluğu. Mucizevi yolculuğu yeni başlıyor!'};

    Map<int, Map<String, String>> data = {
      4: {'fruit': 'Haşhaş Tohumu', 'desc': 'Hamileliğinizin 4. haftasında bebeğiniz henüz bir haşhaş tohumu tanesi büyüklüğündedir. Boyu henüz ultrason cihazında görülemeyecek kadar küçük, yaklaşık 1-2 mm civarındadır.'},
      5: {'fruit': 'Elma Çekirdeği', 'desc': '5. hafta hamilelikte bebek büyüklüğü 3-4mm kadardır. Kütlesi ise henüz ölçülemeyecek kadar küçüktür. Bu hafta bebeğinizin kütlesi ölçülemese de kalp atışları ultrason cihazından dinlenebilir.'},
      6: {'fruit': 'Bezelye', 'desc': 'İşte bu hafta bebeğinizi minik bezelyem diye sevebilirsiniz, çünkü boyu bir bezelye tanesi kadar. Tabi bu kadar küçük bir bebeğin kilosundan bahsedemeyiz.'},
      7: {'fruit': 'Yaban Mersini', 'desc': 'Yedi haftalık hamilelikte bebek büyüklüğü bir yaban mersini tanesi kadardır. Ultrason cihazı bu haftada miniğinizi 7-8 mm civarında ölçecektir.'},
      8: {'fruit': 'Barbunya', 'desc': 'Nihayet bebeğinizin kilosu artık ölçülebiliyor. 8 haftalık hamilelikte bebeğin kilosu yaklaşık 1 gram; boyu ise yaklaşık 1,5 cm’ dir. Bu hafta bebeğinizi tatlı barbunyam diye sevebilirsiniz.'},
      9: {'fruit': 'Üzüm Tanesi', 'desc': 'Bu hafta bir üzüm tanesi kadar olan embriyonuz ortalama 2 cm boyunda ve 2 gram ağırlığındadır.'},
      10: {'fruit': 'Çilek', 'desc': 'Meyve ve sebzeler ile bebek büyüklüğünü karşılaştırırsak, bebeğiniz bir çilek boyuna ancak 10 haftalıkken gelebilecektir. Çileğiniz yaklaşık 3 cm boyunda ve 4 gram ağırlığında olacaktır.'},
      11: {'fruit': 'İncir', 'desc': 'Bebeğiniz 11. gebelik haftasında neredeyse bir incir boyuna ulaşır. Hem de 4 cm boylarında, 7 gram ağırlığında tatlı mı tatlı bir incir.'},
      12: {'fruit': 'Misket Limonu', 'desc': 'Bu hafta; ortalama 5 cm boyunda, 15 gram ağırlığında ve yaklaşık bir misket limonu büyüklüğünde bir bebeğiniz var.'},
      13: {'fruit': 'Limon', 'desc': 'Meyve ve sebzelere benzeterek yaptığımız bu karşılaşmada 13. haftaya ulaştık. Artık 7 cm boyunda, 25 gram kütleli ve yaklaşık bir limon boylarında bir bebeği karnınızda taşıyorsunuz.'},
      14: {'fruit': 'Şeftali', 'desc': '14 hafta hamilelikte anne karnında bebeğin boyu ve kilosu hakkında konuşacak olursak; boyu yaklaşık bir şeftali kadar, yani 9 cm’dir. Kilosu ise 45 gramdır.'},
      15: {'fruit': 'Elma', 'desc': 'Hamileliğinizin bu haftasında bebeğiniz, ortalama 10 santimetrelik tatlı ve sulu bir elma boyunda, 70 gram kadardır.'},
      16: {'fruit': 'Avokado', 'desc': 'Bu haftaki anne karnında bebeğin kilosu ve boyu bir avokadoya benzetilebilir. Bu avokadonun boyu yaklaşık 11 cm, kütlesi ise 100 gramdır.'},
      17: {'fruit': 'Nar', 'desc': 'Bebeğinizi güzel narım diyerek sevebilirsiniz. Çünkü gebeliğin bu haftasında ortalama bir nar boyundaki bebeğinizin boyu 13 cm, kütlesi ise 150 gram kadardır.'},
      18: {'fruit': 'Enginar', 'desc': 'Hamileliğinizin 18. haftasında bebeğiniz yeşil yaprakları üstünde, henüz soyulmamış orta boy bir enginar kadardır. Değerli enginarınızın boyu 14 santimetreyi, kütlesi 200 gramı bulabilir.'},
      19: {'fruit': 'Mango', 'desc': 'Artık karnınızda pembe, dolgun ve sulu bir mango taşıyorsunuz. Evet, bebeğiniz yaklaşık 15 cm ve 250 grama denk gelebilecek bir mango kadardır.'},
      20: {'fruit': 'Muz', 'desc': '20 haftalık bir bebeğin büyüklüğünü bir muzun büyüklüğü ile karşılaştırabiliriz. Bu haftada bebeğinizin boyu 25 cm, kütlesi 300 gram kadardır.'},
      21: {'fruit': 'Havuç', 'desc': 'Havuç! Ama öyle küçük değil, iri bir havuç düşünün. Bebeğiniz, gebeliğinizin 21. haftasında 27 cm, 350 gramlık iri bir havuç kadardır. Gördüğünüz gibi hamilelikte bebeğin boyu ve kilosu hızla artmaya devam ediyor.'},
      22: {'fruit': 'Hindistan Cevizi', 'desc': '22 haftalık gebelikte miniğiniz artık pek de minik değildir. 28 cm boylarında bir hindistan cevizi kadardır. Kütlesi ise ortalama 430 gram olarak ölçülür.'},
      23: {'fruit': 'Greyfurt', 'desc': 'Gebeliğin 23. haftasında karnınızda kocaman ve dolgun bir greyfurt taşıyorsunuz. Güzel greyfurtunuz yaklaşık 30 cm boyundadır. Bu hafta bebeğinizin yarım kiloya, yani 500 grama ulaşması beklenir.'},
      24: {'fruit': 'Kavun', 'desc': 'Panik yapmayın! O kocaman kavunlardan değil. Sıra ona da gelecek tabii ama şimdilik boyu şu küçük sarı kavunlar kadar olan bir bebeğiniz var. Bebeğinizin boyu ortalama 32 cm, kütlesi ise 600 gramdır.'},
      25: {'fruit': 'Karnabahar', 'desc': 'Nihayet bebeğiniz beyaz, tertemiz ve çiçek gibi bir karnabahar boyuna ulaştı. Pamuk karnabaharınızın boyu bu hafta neredeyse 34 santimetreye ulaşır. Kütlesi ise yaklaşık 650 gramdır.'},
      26: {'fruit': 'Kabak', 'desc': 'Meyve ve sebzeler ile büyüklüğü karşılaştırılan bebeğinizin 26. haftada boyu bir kabak kadardır. Bu hafta ultrason cihazı bebeğinizi ortalama 35 cm, 760 gr kadar ölçer.'},
      27: {'fruit': 'Kıvırcık', 'desc': '27. haftada kütlesi değil ama boyu küçük boy bir kıvırcığa yetişmiştir. Bebeğinizin 37 cm, 875 gram gibi boy ve kütle değerlerine sahip olması beklenir.'},
      28: {'fruit': 'Patlıcan', 'desc': 'İri, tam karnıyarıklık bir patlıcanın boyuna yetişen bebeğinizin boyunun yaklaşık 37 cm olması beklenir. İste size iyi haber, bu hafta bebeğiniz yaklaşık 1 kg olur.'},
      29: {'fruit': 'Tatume Kabağı', 'desc': 'Tatume kabağını hiç duymuş muydunuz? İşte bebeğiniz şuan onun kadar. Bu kabakçığın boyu 39 cm, kütlesi 1150 gram olabilir.'},
      30: {'fruit': 'Lahana', 'desc': 'Meyve ve sebzelere benzeterek yaptığımız bu karşılaştırmada bebeğiniz artık bir lahananın boyuna erişti. Boyu 40 cm olan beyaz lahananızın kütlesi ise henüz bir lahanaya yetişmedi. Sadece 1300 gram.'},
      31: {'fruit': 'Kuşkonmaz Demeti', 'desc': '31. haftada bebeğinizin boyu koca bir kuşkonmaz demeti kadardır. Nefis ve taze kuşkonmazınızın boyu ultrason cihazında 40 cm, kütlesi 1500 gram okunabilir.'},
      32: {'fruit': 'Su Kabağı', 'desc': 'Bu hafta bebeğiniz su kabağı boyuna yetişti. Boyu yaklaşık 42 cm, kütlesi 1700 gramdır.'},
      33: {'fruit': 'Kereviz', 'desc': 'Topanıyla, sapıyla kocaman bir kereviz kadar oldu bebeğiniz. Hamilelikte 33. haftada bebeğiniz 43 cm, 1900 gr kadardır.'},
      34: {'fruit': 'Kavun', 'desc': '34 hafta hamilelikte anne karnında bebeğin boyu ve kilosu hakkında konuşacak olursak; boyu yaklaşık orta boy bir kavun kadar; yani 45 cm, kilosu ise 2150 gramdır.'},
      35: {'fruit': 'Ananas', 'desc': 'Yeşil sapıyla ve gövdesiyle neredeyse iri bir ananas boyuna yetişen bebeğinizin boyu 46 cm, kütlesi ise 2400 grama erişir.'},
      36: {'fruit': 'Papaya', 'desc': 'Tatlı, sevimli, 47 cm boylarında, 2600 gram kütleli papayanız bu haftadan itibaren artık karnınızı daha güçlü tekmeleyip duracak.'},
      37: {'fruit': 'Marul', 'desc': '37 haftalık hamilelikte bebeğin boyu ve kilosu uzun bir marul kadardır. Yani ortalama 48 cm. Kütlesi ise 2800 gramı bulabilir.'},
      38: {'fruit': 'Kış Kabağı', 'desc': 'Henüz bal kabağı değil, kış kabağı kadar. Bu kabakçık 50 cm boylarında, 3000 gr kadar olabilir. :)'},
      39: {'fruit': 'Bal Kabağı', 'desc': 'Meyve ve sebzelere benzeterek yaptığımız karşılaştırmada 39. hafta, bebeğinizin bir bal kabağı kadar olduğu haftadır. Bu bal kabağı 51 cm, 3200 gram olabilir.'},
      40: {'fruit': 'Karpuz', 'desc': '40 hafta hamilelikte bebeğin boyu ve kilosu nihayet bir karpuza yetişti. Bebeğiniz bu hafta 51 cm boyunda ve 3400 gram kütleli olabilir.'},
    };
    if (week > 40) return data[40]!;
    return data[week]!;
  }

  Future<void> _loadDailyDataFromDB() async {
    String today = DateTime.now().toIso8601String().substring(0, 10);
    int userId = widget.user['id'];
    var log = await DatabaseHelper.instance.getDailyLog(userId, today);
    if (log != null) {
      setState(() {
        _waterDrank = log['water_drank'] ?? 0.0;
        _loveCount = log['love_count'] ?? 0;
        _todayDiet = List<Map<String, dynamic>>.from(jsonDecode(log['diet_data']));
        _todayExercises = List<Map<String, dynamic>>.from(jsonDecode(log['exercise_data']));
        _isLoading = false;
      });
    } else {
      _generateDefaultLists();
      await DatabaseHelper.instance.insertDailyLog({
        'user_id': userId, 'date': today, 'water_drank': 0.0, 'love_count': 0,
        'diet_data': jsonEncode(_todayDiet), 'exercise_data': jsonEncode(_todayExercises),
      });
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDataToDB() async {
    String today = DateTime.now().toIso8601String().substring(0, 10);
    await DatabaseHelper.instance.updateDailyLog(widget.user['id'], today, {
      'water_drank': _waterDrank, 'love_count': _loveCount,
      'diet_data': jsonEncode(_todayDiet), 'exercise_data': jsonEncode(_todayExercises),
    });
  }

  void _generateDefaultLists() {
    bool isPregnant = widget.user['is_pregnant'] == 1;
    int dayOfWeek = DateTime.now().weekday;
    if (dayOfWeek % 2 == 0) {
      _todayDiet = [
        {'time': 'Kahvaltı', 'item': 'Haşlanmış yumurta, 2 dilim tam buğday ekmeği, beyaz peynir, 5 adet zeytin, bol yeşillik.', 'done': false},
        {'time': '1. Ara Öğün', 'item': '1 bardak kefir veya probiyotik yoğurt.', 'done': false},
        {'time': 'Öğle', 'item': 'Izgara tavuk göğsü (150g), kinoa salatası, zeytinyağlı sebze.', 'done': false},
        {'time': '2. Ara Öğün', 'item': '1 porsiyon meyve ve 10 çiğ badem.', 'done': false},
        {'time': 'Akşam', 'item': 'Fırın somon, yanına bol limonlu yeşil salata.', 'done': false},
        {'time': '3. Ara Öğün (Gece)', 'item': 'Papatya çayı ve 2 adet ceviz.', 'done': false},
      ];
    } else {
      _todayDiet = [
        {'time': 'Kahvaltı', 'item': 'Yulaf lapası (Süt, yarım muz, tarçın).', 'done': false},
        {'time': '1. Ara Öğün', 'item': '1 avuç kabak çekirdeği ve elma suyu.', 'done': false},
        {'time': 'Öğle', 'item': 'Etli kuru fasulye, az porsiyon bulgur pilavı, cacık.', 'done': false},
        {'time': '2. Ara Öğün', 'item': '2 adet kuru incir, Türk kahvesi.', 'done': false},
        {'time': 'Akşam', 'item': 'Yağsız dana sote, fırınlanmış kök sebzeler.', 'done': false},
        {'time': '3. Ara Öğün (Gece)', 'item': 'Yarım bardak ılık süt.', 'done': false},
      ];
    }
    _todayExercises = isPregnant ? [
      {'title': 'Pelvik Taban (Kegel)', 'desc': '3 Set / 10 Tekrar', 'done': false},
      {'title': 'Hamile Pilatesi', 'desc': 'Sırt ve bel ağrıları için esneme (15 dk)', 'done': false},
      {'title': 'Hafif Yürüyüş', 'desc': 'Temiz havada (20 dk)', 'done': false},
    ] : [
      {'title': 'Postür Düzeltme', 'desc': 'Emzirme kaynaklı sırt ağrıları için esneme', 'done': false},
      {'title': 'Nefes Egzersizleri', 'desc': 'Diyafram nefesi (10 dk)', 'done': false},
      {'title': 'Hafif Yürüyüş', 'desc': 'Bebek arabası ile (30 dk)', 'done': false},
    ];
  }

  void _petTheBaby() {
    final key = UniqueKey();
    setState(() {
      _loveCount++;
      _hearts.add(FloatingHeart(
        key: key, horizontalOffset: _random.nextDouble() * 60 - 30,
        onComplete: () => setState(() => _hearts.removeWhere((w) => w.key == key)),
      ));
    });
    _saveDataToDB();
  }

  Widget _buildHomeTab() {
    int week = _calculatedCurrentWeek;
    var babyInfo = _getBabyInfo(week);

    double dynamicBabySize = 50.0 + ((week.clamp(4, 40) - 4) * 3.3);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$week. Hafta Gebelik', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFD67B8E))),
              const SizedBox(height: 25),

              GestureDetector(
                onTap: _petTheBaby,
                child: Container(
                  width: 260,
                  height: 340,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFFD67B8E).withOpacity(0.6), width: 4),
                    boxShadow: [
                      BoxShadow(color: Colors.pink.withOpacity(0.08), blurRadius: 15, spreadRadius: 2, offset: const Offset(0, 5))
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutBack,
                            width: dynamicBabySize,
                            height: dynamicBabySize + 20,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFD67B8E), width: 2),
                              boxShadow: [
                                BoxShadow(color: const Color(0xFFD67B8E).withOpacity(0.15), blurRadius: 10, spreadRadius: 1)
                              ],
                            ),
                            child: Center(
                              child: Text('🍼', style: TextStyle(fontSize: dynamicBabySize > 80 ? 40 : 25)),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                              babyInfo['fruit']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)
                          ),
                          const Text('Büyüklüğünde', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(scale: animation, child: child),
                child: Text(
                  'Bugün bebeğinizi $_loveCount kere sevdiniz 💖',
                  key: ValueKey<int>(_loveCount),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.pinkAccent),
                ),
              ),

              const SizedBox(height: 65),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
                    border: Border.all(color: const Color(0xFFFCE4EC), width: 2)
                ),
                child: Column(
                  children: [
                    const Center(
                      child: Text('Gelişim Notu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFD67B8E))),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      babyInfo['desc']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.6, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ..._hearts,
      ],
    );
  }

  Widget _buildFeedTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Günün Akışı ve Sağlık', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 15),
        _buildNewsCard('Doğumun Anne Vücuduna Yararları', 'Hücre yenilenmesi, hormonal denge ve uzun vadeli bağışıklık sistemi üzerindeki mucizevi etkileri.', Colors.green, 'Doğum yapmak, kadın vücudunda muazzam bir biyolojik dönüşümü tetikler. Gebelik boyunca üretilen hormonlar doğumdan sonra dengelenirken, emzirme süreciyle birlikte rahim hızla eski boyutuna döner. Yapılan araştırmalar, emzirmenin ve doğal doğum süreçlerinin anneyi meme ve yumurtalık kanseri riskine karşı uzun vadede koruduğunu göstermektedir. Ayrıca bu süreçte vücut, hücresel düzeyde yenilenme yaşar ve oksitosin (sevgi hormonu) salgılanması sayesinde annelik bağı güçlenirken stres seviyeleri doğal yollarla minimuma indirgenir.'),
        _buildNewsCard('Lohusalıkta Psikolojik Destek', 'Kendinize zaman ayırmanın, duygularınızı ifade etmenin ve çevresel desteğin önemi üzerine uzman görüşleri.', Colors.purple, 'Doğum sonrası dönem (lohusalık), fiziksel iyileşmenin yanı sıra ciddi hormonal dalgalanmaların yaşandığı psikolojik bir eşiktir. "Bebek hüznü" olarak adlandırılan hafif hüzün ve kaygı halleri ilk haftalarda normal kabul edilirken, bu sürecin uzaması lohusalık depresyonuna işaret edebilir. Uzmanlar, annelerin bu dönemde her şeye tek başına yetişmeye çalışmamalarını, çevrelerinden (özellikle eşlerinden) aktif yardım talep etmelerini önermektedir. Unutmayın, sağlıklı bir bebek ancak sağlıklı ve mutlu bir anne ile büyüyebilir. Kendinize gün içinde küçük dinlenme molaları yaratmak lüks değil, tıbbi bir ihtiyaçtır.'),
        _buildNewsCard('Kadın Sağlığı ve Kontroller', 'Doğum sonrası rahim toparlanması, pelvik taban egzersizleri (Kegel) ve rutin smear testleri.', Colors.blue, 'Doğum gerçekleştikten sonra hastaneden taburcu olmak tıbbi takibin bittiği anlamına gelmez. Doğum sonrası 6. haftada mutlaka kadın hastalıkları ve doğum uzmanına rutin kontrole gidilmelidir. Bu kontrolde rahmin toparlanma hızı, dikişlerin durumu (sezaryen veya normal doğum dikişleri) incelenir. Ayrıca pelvik taban kaslarının eski gücüne kavuşabilmesi ve ilerleyen yaşlarda idrar kaçırma gibi problemler yaşanmaması için "Kegel egzersizleri" günlük rutine eklenmelidir. Doktorunuzun onayladığı takvimde smear testlerinin yenilenmesi de üreme sağlığının korunması açısından kritiktir.'),
        _buildNewsCard('Emzirme ve Anne Sütü', 'Anne sütünün bebeğin zihinsel gelişimine katkısı ve emzirme döneminde artan kalori ihtiyacı.', Colors.orange, 'Anne sütü, bir bebeğin doğduğu andan itibaren ihtiyaç duyduğu tüm makro ve mikro besinleri tam zamanlı ve doğru ısıda içeren, taklit edilemez canlı bir sıvıdır. İlk günlerde gelen "kolostrum" (ağız sütü), bebeğin ilk doğal aşısıdır ve bağışıklık sisteminin temelini atar. Emzirme, sadece bebeği beslemekle kalmaz; annenin günlük yaklaşık 500 kalori fazladan yakmasını sağlayarak doğum kilolarından doğal yolla kurtulmasına yardım eder. Bu dönemde annenin su tüketimi süt miktarını doğrudan etkiler. Bebeğin beyin ve sinir gelişimi için ilk 6 ay sadece anne sütü, uzmanların ortak tavsiyesidir.'),
      ],
    );
  }

  Widget _buildNewsCard(String title, String subtitle, Color color, String content) {
    return Card(
      elevation: 3, margin: const EdgeInsets.only(bottom: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => ArticleDetailScreen(title: title, content: content, color: color))); },
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
              const SizedBox(height: 12),
              Text(subtitle, style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.4)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Devamını Oku', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                  const SizedBox(width: 5),
                  Icon(Icons.arrow_forward, size: 14, color: color),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyTasksTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Günlük Akış ve Takip', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal)),
        const SizedBox(height: 20),
        Card(
          elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.water_drop, color: Colors.blue, size: 40),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Su Tüketimi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('Hedef: $_waterTarget L / İçilen: ${_waterDrank.toStringAsFixed(2)} L', style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                LinearProgressIndicator(value: _waterDrank / _waterTarget, backgroundColor: Colors.blue[100], color: Colors.blue, minHeight: 10),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () { setState(() { if (_waterDrank < _waterTarget) { _waterDrank += 0.25; _saveDataToDB(); }});},
                  icon: const Icon(Icons.add), label: const Text('+ 250 ml Ekle'),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Bugünkü Egzersizlerin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: _todayExercises.map((exercise) {
              return CheckboxListTile(
                title: Text(exercise['title'], style: TextStyle(fontWeight: FontWeight.bold, decoration: exercise['done'] ? TextDecoration.lineThrough : null)),
                subtitle: Text(exercise['desc'], style: TextStyle(decoration: exercise['done'] ? TextDecoration.lineThrough : null)),
                activeColor: Colors.teal, value: exercise['done'],
                onChanged: (bool? val) { setState(() { exercise['done'] = val!; _saveDataToDB(); });},
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Günün Beslenme Planı', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Card(
          elevation: 3, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Column(
            children: _todayDiet.map((dietItem) {
              return CheckboxListTile(
                title: Text(dietItem['time'], style: TextStyle(fontWeight: FontWeight.bold, decoration: dietItem['done'] ? TextDecoration.lineThrough : null)),
                subtitle: Text(dietItem['item'], style: TextStyle(decoration: dietItem['done'] ? TextDecoration.lineThrough : null)),
                activeColor: const Color(0xFFD67B8E), value: dietItem['done'],
                onChanged: (bool? val) { setState(() { dietItem['done'] = val!; _saveDataToDB(); });},
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChildrenTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DatabaseHelper.instance.database.then((db) => db.query('children', where: 'parent_id = ?', whereArgs: [widget.user['id']])),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('Henüz bebek kaydı bulunmuyor.', style: TextStyle(fontSize: 16)));
        final children = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(20), itemCount: children.length,
          itemBuilder: (context, index) {
            final child = children[index];
            final bool isBoy = child['gender'] == 'Erkek';
            final Color circleColor = isBoy ? Colors.blue.shade400 : const Color(0xFFD67B8E);
            final String initialLetter = child['child_name'].toString().isNotEmpty ? child['child_name'][0].toUpperCase() : '';
            return Card(
              elevation: 4, margin: const EdgeInsets.only(bottom: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ExpansionTile(
                leading: CircleAvatar(backgroundColor: circleColor, radius: 20, child: Text(initialLetter, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                title: Text(child['child_name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                subtitle: Text('${child['birth_date']} - ${child['birth_time']}', style: const TextStyle(fontSize: 15)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Temel Ölçümler ve Doğum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                        const SizedBox(height: 8),
                        Text('Doğum Yeri: ${child['birth_place']}', style: const TextStyle(fontSize: 16, height: 1.5)),
                        Text('Doğum Şekli: ${child['delivery_type']}', style: const TextStyle(fontSize: 16, height: 1.5)),
                        Text('Doğum Süresi: ${child['gestation_week']}. Hafta', style: const TextStyle(fontSize: 16, height: 1.5)),
                        Text('Doktor: ${child['doctor_name']}', style: const TextStyle(fontSize: 16, height: 1.5)),
                        Text('Ebeler: ${child['midwives']}', style: const TextStyle(fontSize: 16, height: 1.5)),
                        const Divider(height: 24, thickness: 1),
                        Text('Kilo: ${child['weight_gr']} gr   Boy: ${child['height']} cm', style: const TextStyle(fontSize: 16, height: 1.5)),
                        Text('Baş Çevresi: ${child['head_circumference']} cm   Ateş: ${child['birth_fever']} °C', style: const TextStyle(fontSize: 16, height: 1.5)),
                        const Divider(height: 24, thickness: 1),
                        const Text('Kritik Tıbbi Geçmiş', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.redAccent)),
                        const SizedBox(height: 8),
                        if (child['is_premature'] == 1) ...[
                          const Text('Erken Doğum (Prematüre): Evet', style: TextStyle(fontSize: 16, height: 1.5)),
                          Text('Küvezde Kalma Süresi: ${child['incubator_days']} Gün', style: const TextStyle(fontSize: 16, height: 1.5)),
                        ] else const Text('Zamanında Doğum', style: TextStyle(fontSize: 16, height: 1.5)),
                        if (child['has_disease'] == 1) ...[
                          const SizedBox(height: 5),
                          Text('Tespit Edilen Hastalık/Sendrom: ${child['diseases'] != "" ? child['diseases'] : "Belirtilmedi"}', style: const TextStyle(fontSize: 16, height: 1.5)),
                        ] else const Text('Tespit Edilen Hastalık: Yok', style: TextStyle(fontSize: 16, height: 1.5)),
                        const Divider(height: 24, thickness: 1),
                        const Text('Aşı Durumu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue)),
                        const SizedBox(height: 8),
                        Text('Yapılan Aşılar: ${child['vaccines'] != "" ? child['vaccines'] : "Aşı Kaydı Yok"}', style: const TextStyle(fontSize: 16, height: 1.5)),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    bool isPregnant = widget.user['is_pregnant'] == 1;

    List<Widget> pages = isPregnant
        ? [_buildHomeTab(), _buildFeedTab(), _buildDailyTasksTab(), _buildChildrenTab()]
        : [_buildFeedTab(), _buildDailyTasksTab(), _buildChildrenTab()];

    List<BottomNavigationBarItem> navItems = isPregnant
        ? const [
      BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Bebeğim'),
      BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Akış'),
      BottomNavigationBarItem(icon: Icon(Icons.local_dining), label: 'Takip'),
      BottomNavigationBarItem(icon: Icon(Icons.child_care), label: 'Çocuklarım'),
    ]
        : const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Ana Sayfa'),
      BottomNavigationBarItem(icon: Icon(Icons.local_dining), label: 'Takip'),
      BottomNavigationBarItem(icon: Icon(Icons.child_care), label: 'Çocuklarım'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(
        title: Text('Hoşgeldin, ${widget.user['name']}'),
        backgroundColor: const Color(0xFFD67B8E), foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (String value) {
              if (value == 'logout') {
                Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => const LoginScreen()), (Route<dynamic> route) => false);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(value: 'logout', child: Row(children: [Icon(Icons.exit_to_app, color: Colors.black54), SizedBox(width: 8), Text('Çıkış Yap')])),
            ],
          ),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex, onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFFD67B8E), unselectedItemColor: Colors.grey, items: navItems,
      ),
    );
  }
}

class ArticleDetailScreen extends StatelessWidget {
  final String title; final String content; final Color color;
  const ArticleDetailScreen({super.key, required this.title, required this.content, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5),
      appBar: AppBar(title: const Text('Makale Detayı'), backgroundColor: const Color(0xFFD67B8E), foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
            const Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Divider(thickness: 1.5)),
            Text(content, style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.6), textAlign: TextAlign.justify),
          ],
        ),
      ),
    );
  }
}

class FloatingHeart extends StatefulWidget {
  final VoidCallback onComplete; final double horizontalOffset;
  const FloatingHeart({super.key, required this.onComplete, required this.horizontalOffset});
  @override State<FloatingHeart> createState() => _FloatingHeartState();
}
class _FloatingHeartState extends State<FloatingHeart> with SingleTickerProviderStateMixin {
  late AnimationController _controller; late Animation<double> _v, _o;
  @override void initState() { super.initState(); _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200)); _v = Tween<double>(begin: 0, end: 150).animate(_controller); _o = Tween<double>(begin: 1.0, end: 0).animate(_controller); _controller.forward().then((_) => widget.onComplete()); }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(animation: _controller, builder: (c, child) => Positioned(bottom: MediaQuery.of(c).size.height/2 - 50 + _v.value, left: MediaQuery.of(c).size.width/2 - 20 + widget.horizontalOffset, child: Opacity(opacity: _o.value, child: const Icon(Icons.favorite, color: Colors.pinkAccent, size: 40))));
}