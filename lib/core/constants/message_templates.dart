import '../../core/localization/app_localizations.dart';

enum MessageCategory {
  price,
  contract,
  location,
  meeting;

  String get displayName {
    switch (this) {
      case MessageCategory.price:
        return 'Price';
      case MessageCategory.contract:
        return 'Contract';
      case MessageCategory.location:
        return 'Location';
      case MessageCategory.meeting:
        return 'Meeting';
    }
  }
}

class ChatMessageTemplate {
  final String id;
  final MessageCategory category;
  final String enContent;
  final String arContent;
  final String frContent;
  final bool isQuestion;
  final String? answersQuestionId;

  const ChatMessageTemplate({
    required this.id,
    required this.category,
    required this.enContent,
    required this.arContent,
    required this.frContent,
    required this.isQuestion,
    this.answersQuestionId,
  });

  String getLocalizedContent(AppLocalizations? l10n) {
    if (l10n == null) return enContent;

    final locale = l10n.localeName;
    if (locale == 'ar') return arContent;
    if (locale == 'fr') return frContent;
    return enContent;
  }

  String getEncodedContent(AppLocalizations? l10n) {
    final content = getLocalizedContent(l10n);
    if (isQuestion) {
      return '[Q:$id]$content';
    } else if (answersQuestionId != null) {
      return '[A:$answersQuestionId:$id]$content';
    }
    return content;
  }
}

class MessageTemplates {
  static const List<ChatMessageTemplate> all = [
    // PRICE QUESTIONS
    ChatMessageTemplate(
      id: 'price_q1',
      category: MessageCategory.price,
      enContent: 'Is the listed rental price negotiable?',
      arContent: 'هل سعر الإيجار المحدد قابل للتفاوض؟',
      frContent: 'Le prix de location indiqué est-il négociable ?',
      isQuestion: true,
    ),
    ChatMessageTemplate(
      id: 'price_q2',
      category: MessageCategory.price,
      enContent: 'Would you consider a different payment schedule?',
      arContent: 'هل تقبل جدول دفع مختلف؟',
      frContent: 'Accepteriez-vous un calendrier de paiement différent ?',
      isQuestion: true,
    ),
    ChatMessageTemplate(
      id: 'price_q3',
      category: MessageCategory.price,
      enContent: 'Are utilities included in the rent?',
      arContent: 'هل المرافق مشمولة في الإيجار؟',
      frContent: 'Les services sont-ils inclus dans le loyer ?',
      isQuestion: true,
    ),

    // PRICE ANSWERS
    ChatMessageTemplate(
      id: 'price_ans_yes',
      category: MessageCategory.price,
      enContent: 'Yes',
      arContent: 'نعم',
      frContent: 'Oui',
      isQuestion: false,
      answersQuestionId: 'price_q1',
    ),
    ChatMessageTemplate(
      id: 'price_ans_no',
      category: MessageCategory.price,
      enContent: 'No',
      arContent: 'لا',
      frContent: 'Non',
      isQuestion: false,
      answersQuestionId: 'price_q1',
    ),
    ChatMessageTemplate(
      id: 'price_ans_discuss',
      category: MessageCategory.price,
      enContent: "Let's discuss further",
      arContent: 'دعنا نناقش أكثر',
      frContent: 'Discutons-en davantage',
      isQuestion: false,
      answersQuestionId: 'price_q1',
    ),

    // CONTRACT QUESTIONS
    ChatMessageTemplate(
      id: 'contract_q1',
      category: MessageCategory.contract,
      enContent: 'Are you flexible on the contract duration?',
      arContent: 'هل أنت مرن بشأن مدة العقد؟',
      frContent: 'Êtes-vous flexible sur la durée du contrat ?',
      isQuestion: true,
    ),
    ChatMessageTemplate(
      id: 'contract_q2',
      category: MessageCategory.contract,
      enContent: 'Do you allow subletting?',
      arContent: 'هل تسمح بإعادة الإيجار؟',
      frContent: 'Autorisez-vous la sous-location ?',
      isQuestion: true,
    ),
    ChatMessageTemplate(
      id: 'contract_q3',
      category: MessageCategory.contract,
      enContent: 'Is a deposit required?',
      arContent: 'هل يلزم وديعة؟',
      frContent: 'Un dépôt est-il requis ?',
      isQuestion: true,
    ),

    // CONTRACT ANSWERS
    ChatMessageTemplate(
      id: 'contract_ans_yes',
      category: MessageCategory.contract,
      enContent: 'Yes',
      arContent: 'نعم',
      frContent: 'Oui',
      isQuestion: false,
      answersQuestionId: 'contract_q1',
    ),
    ChatMessageTemplate(
      id: 'contract_ans_no',
      category: MessageCategory.contract,
      enContent: 'No',
      arContent: 'لا',
      frContent: 'Non',
      isQuestion: false,
      answersQuestionId: 'contract_q1',
    ),
    ChatMessageTemplate(
      id: 'contract_ans_discuss',
      category: MessageCategory.contract,
      enContent: "Let's discuss further",
      arContent: 'دعنا نناقش أكثر',
      frContent: 'Discutons-en davantage',
      isQuestion: false,
      answersQuestionId: 'contract_q1',
    ),

    // LOCATION QUESTIONS
    ChatMessageTemplate(
      id: 'location_q1',
      category: MessageCategory.location,
      enContent: 'Is parking available?',
      arContent: 'هل يتوفر موقف سيارات؟',
      frContent: 'Un parking est-il disponible ?',
      isQuestion: true,
    ),
    ChatMessageTemplate(
      id: 'location_q2',
      category: MessageCategory.location,
      enContent: 'Are pets allowed?',
      arContent: 'هل الحيوانات الأليفة مسموحة؟',
      frContent: 'Les animaux de compagnie sont-ils autorisés ?',
      isQuestion: true,
    ),
    ChatMessageTemplate(
      id: 'location_q3',
      category: MessageCategory.location,
      enContent: 'Is the property accessible by public transport?',
      arContent: 'هل يمكن الوصول إلى العقار بوسائل النقل العام؟',
      frContent: 'La propriété est-elle accessible par les transports en commun ?',
      isQuestion: true,
    ),

    // LOCATION ANSWERS
    ChatMessageTemplate(
      id: 'location_ans_yes',
      category: MessageCategory.location,
      enContent: 'Yes',
      arContent: 'نعم',
      frContent: 'Oui',
      isQuestion: false,
      answersQuestionId: 'location_q1',
    ),
    ChatMessageTemplate(
      id: 'location_ans_no',
      category: MessageCategory.location,
      enContent: 'No',
      arContent: 'لا',
      frContent: 'Non',
      isQuestion: false,
      answersQuestionId: 'location_q1',
    ),
    ChatMessageTemplate(
      id: 'location_ans_discuss',
      category: MessageCategory.location,
      enContent: "Let's discuss further",
      arContent: 'دعنا نناقش أكثر',
      frContent: 'Discutons-en davantage',
      isQuestion: false,
      answersQuestionId: 'location_q1',
    ),

    // MEETING QUESTIONS
    ChatMessageTemplate(
      id: 'meeting_q1',
      category: MessageCategory.meeting,
      enContent: 'Are you available for a property visit?',
      arContent: 'هل أنت متاح لزيارة العقار؟',
      frContent: 'Êtes-vous disponible pour une visite de la propriété ?',
      isQuestion: true,
    ),
    ChatMessageTemplate(
      id: 'meeting_q2',
      category: MessageCategory.meeting,
      enContent: 'Can we schedule a meeting to discuss terms?',
      arContent: 'هل يمكننا جدولة اجتماع لمناقشة الشروط؟',
      frContent: 'Pouvons-nous programmer une réunion pour discuter des conditions ?',
      isQuestion: true,
    ),

    // MEETING ANSWERS — for meeting_q1
    ChatMessageTemplate(
      id: 'meeting_ans_yes',
      category: MessageCategory.meeting,
      enContent: "Yes, I'm available",
      arContent: 'نعم، أنا متاح',
      frContent: "Oui, je suis disponible",
      isQuestion: false,
      answersQuestionId: 'meeting_q1',
    ),
    ChatMessageTemplate(
      id: 'meeting_ans_no',
      category: MessageCategory.meeting,
      enContent: 'Not available currently',
      arContent: 'غير متاح حالياً',
      frContent: 'Pas disponible actuellement',
      isQuestion: false,
      answersQuestionId: 'meeting_q1',
    ),
    ChatMessageTemplate(
      id: 'meeting_ans_contact',
      category: MessageCategory.meeting,
      enContent: 'Please contact me to arrange',
      arContent: 'يرجى الاتصال بي لترتيب الموعد',
      frContent: 'Veuillez me contacter pour organiser',
      isQuestion: false,
      answersQuestionId: 'meeting_q1',
    ),

    // MEETING ANSWERS — for meeting_q2
    ChatMessageTemplate(
      id: 'meeting_q2_ans_yes',
      category: MessageCategory.meeting,
      enContent: "Yes, let's schedule a meeting",
      arContent: 'نعم، دعنا نحدد موعداً',
      frContent: "Oui, planifions une réunion",
      isQuestion: false,
      answersQuestionId: 'meeting_q2',
    ),
    ChatMessageTemplate(
      id: 'meeting_q2_ans_no',
      category: MessageCategory.meeting,
      enContent: 'Not right now',
      arContent: 'ليس الآن',
      frContent: 'Pas maintenant',
      isQuestion: false,
      answersQuestionId: 'meeting_q2',
    ),
    ChatMessageTemplate(
      id: 'meeting_q2_ans_contact',
      category: MessageCategory.meeting,
      enContent: 'Please contact me to arrange',
      arContent: 'يرجى الاتصال بي لترتيب الموعد',
      frContent: 'Veuillez me contacter pour organiser',
      isQuestion: false,
      answersQuestionId: 'meeting_q2',
    ),
  ];

  static String extractContent(String raw) {
    if (raw.startsWith('[Q:') || raw.startsWith('[A:')) {
      final endIdx = raw.indexOf(']');
      if (endIdx != -1) {
        return raw.substring(endIdx + 1);
      }
    }
    return raw;
  }

  static bool isQuestion(String raw) => raw.startsWith('[Q:');

  static bool isAnswer(String raw) => raw.startsWith('[A:');

  static String? getQuestionId(String raw) {
    if (!raw.startsWith('[Q:')) return null;
    final start = 3;
    final end = raw.indexOf(']');
    if (end == -1) return null;
    return raw.substring(start, end);
  }

  static String? getAnsweredQuestionId(String raw) {
    if (!raw.startsWith('[A:')) return null;
    final start = 3;
    final end = raw.indexOf(':', start);
    if (end == -1) return null;
    return raw.substring(start, end);
  }

  /// Extracts the answer template id from '[A:questionId:answerId]content'
  static String? getAnswerTemplateId(String raw) {
    if (!raw.startsWith('[A:')) return null;
    final headerEnd = raw.indexOf(']');
    if (headerEnd == -1) return null;
    final header = raw.substring(3, headerEnd); // 'questionId:answerId'
    final sep = header.indexOf(':');
    if (sep == -1) return null;
    return header.substring(sep + 1);
  }

  static List<ChatMessageTemplate> getQuestionsForCategory(MessageCategory cat) {
    return all.where((t) => t.category == cat && t.isQuestion).toList();
  }

  static List<ChatMessageTemplate> getAnswersForQuestion(String questionId) {
    return all
        .where((t) => !t.isQuestion && t.answersQuestionId == questionId)
        .toList();
  }

  static ChatMessageTemplate? getTemplateById(String id) {
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
