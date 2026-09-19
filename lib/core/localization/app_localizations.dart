import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'decision_translations.dart';
import '../../features/home/presentation/home_controller.dart';

const appLanguages = {
  'English': 'English',
  'Hindi': 'हिन्दी',
  'Tamil': 'தமிழ்',
  'Telugu': 'తెలుగు',
};
final stringsProvider = Provider<AppStrings>(
  (ref) => AppStrings(ref.watch(preferencesProvider).language),
);

class AppStrings {
  const AppStrings(this.language);
  final String language;
  String externalLabel(String value, String fallback) {
    if (language == 'English' ||
        decisionTranslations.containsKey(value) ||
        _translations.containsKey(value)) {
      return call(value);
    }
    return call(fallback);
  }
  // Force analyzer update

  String preciseMoney(num value) => NumberFormat.currency(
    locale: locale,
    symbol: '₹',
    decimalDigits: value % 1 == 0 ? 0 : 2,
  ).format(value);
  String day(DateTime value) => DateFormat.yMMMd(locale).format(value);
  String get locale =>
      const {
        'English': 'en_IN',
        'Hindi': 'hi_IN',
        'Tamil': 'ta_IN',
        'Telugu': 'te_IN',
      }[language] ??
      'en_IN';
  String money(num value) => NumberFormat.currency(
    locale: locale,
    symbol: '₹',
    decimalDigits: 0,
  ).format(value);
  String number(num value) => NumberFormat.decimalPatternDigits(
    locale: locale,
    decimalDigits: value % 1 == 0 ? 0 : 1,
  ).format(value);
  String date(DateTime value) =>
      DateFormat.yMMMd(locale).add_jm().format(value.toLocal());
  String format(String key, Map<String, String> values) {
    var result = call(key);
    for (final entry in values.entries) {
      result = result.replaceAll('{${entry.key}}', entry.value);
    }
    return result;
  }

  String call(String key) {
    final index = ['English', 'Hindi', 'Tamil', 'Telugu'].indexOf(language);
    final decision = decisionTranslations[key];
    if (decision != null) return decision[index < 0 ? 0 : index];
    return index <= 0 ? key : (_translations[key]?[index - 1] ?? key);
  }
}

const _translations = <String, List<String>>{
  'Enter valid coordinates': [
    'सही निर्देशांक दर्ज करें',
    'சரியான ஆயங்களை உள்ளிடவும்',
    'సరైన కోఆర్డినేట్లు నమోదు చేయండి',
  ],
  'Could not save or evaluate this harvest. Please try again.': [
    'फसल सहेजने या मूल्यांकन में समस्या। फिर कोशिश करें।',
    'அறுவடையைச் சேமிக்க அல்லது மதிப்பிட முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',
    'పంటను సేవ్ చేయడం లేదా అంచనా వేయడం సాధ్యం కాలేదు. మళ్ళీ ప్రయత్నించండి.',
  ],
  'Could not refresh the estimate': [
    'अनुमान अपडेट नहीं हो सका',
    'மதிப்பீட்டைப் புதுப்பிக்க முடியவில்லை',
    'అంచనాను నవీకరించలేకపోయాము',
  ],
  'No harvest selected': [
    'कोई फसल नहीं चुनी गई',
    'அறுவடை தேர்ந்தெடுக்கப்படவில்லை',
    'పంట ఎంచుకోలేదు',
  ],
  'Sell today': ['आज बेचें', 'இன்று விற்கவும்', 'ఈరోజు అమ్మండి'],
  'Estimated net value': [
    'अनुमानित शुद्ध मूल्य',
    'மதிப்பிடப்பட்ட நிகர மதிப்பு',
    'అంచనా నికర విలువ',
  ],
  'Range': ['सीमा', 'வரம்பு', 'పరిధి'],
  'Baseline': [
    'मौजूदा योजना का मूल्य',
    'தற்போதைய திட்ட மதிப்பு',
    'ప్రస్తుత ప్రణాళిక విలువ',
  ],
  'Difference': ['अंतर', 'வேறுபாடு', 'తేడా'],
  'Other evaluated options': [
    'अन्य विकल्प',
    'மதிப்பிடப்பட்ட பிற வாய்ப்புகள்',
    'ఇతర అంచనా ఎంపికలు',
  ],
  'Estimate details & assumptions': [
    'अनुमान का विवरण और मान्यताएँ',
    'மதிப்பீட்டு விவரங்கள் மற்றும் அனுமானங்கள்',
    'అంచనా వివరాలు మరియు ఊహలు',
  ],
  'Weather': ['मौसम', 'வானிலை', 'వాతావరణం'],
  'Updates are checked when you refresh': [
    'रिफ्रेश करने पर अपडेट जाँचे जाते हैं',
    'புதுப்பிக்கும்போது மாற்றங்கள் சரிபார்க்கப்படும்',
    'రిఫ్రెష్ చేసినప్పుడు నవీకరణలు తనిఖీ చేయబడతాయి',
  ],
  'Refresh estimate': [
    'अनुमान अपडेट करें',
    'மதிப்பீட்டைப் புதுப்பி',
    'అంచనా నవీకరించండి',
  ],
  'Home': ['होम', 'முகப்பு', 'హోమ్'],
  'Register': ['पंजीकरण', 'பதிவு', 'నమోదు'],
  'Decisions': ['निर्णय', 'முடிவுகள்', 'నిర్ణయాలు'],
  'Monitor': ['निगरानी', 'நிலை', 'స్థితి'],
  'Check connection': [
    'कनेक्शन जाँचें',
    'இணைப்பைச் சரிபார்',
    'కనెక్షన్ తనిఖీ చేయండి',
  ],
  'Connection available': [
    'कनेक्शन उपलब्ध है',
    'இணைப்பு உள்ளது',
    'కనెక్షన్ అందుబాటులో ఉంది',
  ],
  'Connection unavailable': [
    'कनेक्शन उपलब्ध नहीं है',
    'இணைப்பு இல்லை',
    'కనెక్షన్ అందుబాటులో లేదు',
  ],
  'Register Harvest': [
    'फसल दर्ज करें',
    'அறுவடையைப் பதிவு செய்',
    'పంటను నమోదు చేయండి',
  ],
  'My Cases': ['मेरी फसलें', 'என் அறுவடைகள்', 'నా పంటలు'],
  'Market Prices': ['बाज़ार भाव', 'சந்தை விலைகள்', 'మార్కెట్ ధరలు'],
  'Settings': ['सेटिंग्स', 'அமைப்புகள்', 'సెట్టింగ్‌లు'],
  'Your harvest, your next step': [
    'आपकी फसल, आपका अगला कदम',
    'உங்கள் அறுவடை, அடுத்த படி',
    'మీ పంట, మీ తదుపరి అడుగు',
  ],
  'Choose your language': [
    'अपनी भाषा चुनें',
    'உங்கள் மொழியைத் தேர்ந்தெடுக்கவும்',
    'మీ భాషను ఎంచుకోండి',
  ],
  'Continue': ['जारी रखें', 'தொடரவும்', 'కొనసాగించండి'],
  'Save': ['सहेजें', 'சேமி', 'సేవ్ చేయండి'],
  'Saved': ['सहेजा गया', 'சேமிக்கப்பட்டது', 'సేవ్ అయింది'],
  'Sign out': ['साइन आउट', 'வெளியேறு', 'సైన్ అవుట్'],
  'Continue with Google': [
    'Google से जारी रखें',
    'Google மூலம் தொடரவும்',
    'Google తో కొనసాగించండి',
  ],
  'Try again': ['फिर कोशिश करें', 'மீண்டும் முயற்சி', 'మళ్ళీ ప్రయత్నించండి'],
  'No harvests yet': [
    'अभी कोई फसल नहीं',
    'இன்னும் அறுவடைகள் இல்லை',
    'ఇంకా పంటలు లేవు',
  ],
  'No market observations yet': [
    'अभी बाज़ार भाव उपलब्ध नहीं',
    'சந்தை விலைகள் இன்னும் இல்லை',
    'మార్కెట్ ధరలు ఇంకా లేవు',
  ],
  'Register harvest details': [
    'फसल का विवरण दर्ज करें',
    'அறுவடை விவரங்களைப் பதிவு செய்',
    'పంట వివరాలు నమోదు చేయండి',
  ],
  'Crop': ['फसल', 'பயிர்', 'పంట'],
  'Net weight': ['कुल वजन', 'நிகர எடை', 'నికర బరువు'],
  'Harvest status': ['कटाई की स्थिति', 'அறுவடை நிலை', 'కోత స్థితి'],
  'Harvested': ['कटाई हो चुकी', 'அறுவடை முடிந்தது', 'కోత పూర్తయింది'],
  'Harvest planned': [
    'कटाई की योजना',
    'அறுவடை திட்டமிடப்பட்டது',
    'కోత ప్రణాళిక',
  ],
  'Standing crop': ['खड़ी फसल', 'வயலில் உள்ள பயிர்', 'పొలంలో ఉన్న పంట'],
  'Harvest date': ['कटाई की तारीख', 'அறுவடை தேதி', 'కోత తేదీ'],
  'Selling deadline': [
    'बेचने की समय सीमा',
    'விற்பனை காலக்கெடு',
    'అమ్మకం గడువు',
  ],
  'Must sell today': [
    'आज ही बेचना है',
    'இன்றே விற்க வேண்டும்',
    'ఈరోజే అమ్మాలి',
  ],
  'Within 2 days': ['2 दिनों में', '2 நாட்களுக்குள்', '2 రోజుల్లో'],
  'Within 3 days': ['3 दिनों में', '3 நாட்களுக்குள்', '3 రోజుల్లో'],
  'Your assessment of quality': [
    'आपके अनुसार गुणवत्ता',
    'உங்கள் தர மதிப்பீடு',
    'మీ నాణ్యత అంచనా',
  ],
  'Ready': ['तैयार', 'தயார்', 'సిద్ధంగా ఉంది'],
  'Ripe': ['पका हुआ', 'பழுத்தது', 'పండినది'],
  'Very ripe': ['बहुत पका', 'மிகவும் பழுத்தது', 'బాగా పండినది'],
  'Mixed': ['मिश्रित', 'கலந்தது', 'మిశ్రమం'],
  'Damaged': ['क्षतिग्रस्त', 'சேதமடைந்தது', 'దెబ్బతిన్నది'],
  'Your current selling plan': [
    'बेचने की आपकी योजना',
    'உங்கள் விற்பனைத் திட்டம்',
    'మీ అమ్మకం ప్రణాళిక',
  ],
  'Farm / harvest location': [
    'खेत / फसल का स्थान',
    'பண்ணை / அறுவடை இடம்',
    'పొలం / పంట ప్రదేశం',
  ],
  'Review facts': [
    'विवरण जाँचें',
    'விவரங்களைச் சரிபார்',
    'వివరాలు పరిశీలించండి',
  ],
  'Confirm crop facts': [
    'फसल विवरण की पुष्टि',
    'பயிர் விவரங்களை உறுதிசெய்',
    'పంట వివరాలు నిర్ధారించండి',
  ],
  'Confirm facts & see recommendation': [
    'पुष्टि करें और सुझाव देखें',
    'உறுதிசெய்து பரிந்துரையைப் பார்',
    'నిర్ధారించి సూచన చూడండి',
  ],
  'Edit': ['बदलें', 'திருத்து', 'సవరించండి'],
  'Cancel': ['रद्द करें', 'ரத்து', 'రద్దు'],
  'Enter a weight between 1 and 100,000 kg': [
    '1 से 100,000 किलो तक वजन दर्ज करें',
    '1 முதல் 100,000 கிலோ வரை உள்ளிடவும்',
    '1 నుండి 100,000 కిలోల బరువు నమోదు చేయండి',
  ],
  'Enter your current plan': [
    'अपनी योजना दर्ज करें',
    'உங்கள் திட்டத்தை உள்ளிடவும்',
    'మీ ప్రణాళిక నమోదు చేయండి',
  ],
  'Enter a location': [
    'स्थान दर्ज करें',
    'இடத்தை உள்ளிடவும்',
    'ప్రదేశం నమోదు చేయండి',
  ],
  'Tomato': ['टमाटर', 'தக்காளி', 'టమాటా'],
  'Okra': ['भिंडी', 'வெண்டைக்காய்', 'బెండకాయ'],
  'Brinjal': ['बैंगन', 'கத்தரிக்காய்', 'వంకాయ'],
  'Latitude (optional)': [
    'अक्षांश (वैकल्पिक)',
    'அட்சரேகை (விருப்பம்)',
    'అక్షాంశం (ఐచ్ఛికం)',
  ],
  'Longitude (optional)': [
    'देशांतर (वैकल्पिक)',
    'தீர்க்கரேகை (விருப்பம்)',
    'రేఖాంశం (ఐచ్ఛికం)',
  ],
};
