class Faq {
  const Faq({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
  });

  final String id;
  final String category;
  final String question;
  final String answer;

  factory Faq.fromJson(Map<String, dynamic> json) => Faq(
    id: json['id'] as String,
    category: json['category'] as String,
    question: json['question'] as String,
    answer: json['answer'] as String,
  );
}

enum SupportTopic {
  order('order', 'Order'),
  payment('payment', 'Payment'),
  account('acoount', 'Account'),
  book('book', 'Book'),
  other('other', 'Other');

  const SupportTopic(this.value, this.label);
  final String value;
  final String label;
}
