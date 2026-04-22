enum Currency {
  cad,
  usd,
  eur,
  jpy;

  static Currency fromStr(String value) {
    return Currency.values.firstWhere(
      (e) => e.name == value,
      orElse: () => Currency.cad,
    );
  }

  String toStr() => name;
}

class Saving {
  final int id;
  final double amount;
  final Currency currency;
  final String? description;
  final DateTime date;
  final DateTime createdAt;

  const Saving({
    required this.id,
    required this.amount,
    this.description,
    required this.date,
    required this.createdAt,
    required this.currency,
  });

  factory Saving.fromJson(Map<String, dynamic> json) {
    return Saving(
      id: json['id'],
      amount: json['amount'].toDouble(),
      description: json['description'],
      date: DateTime.parse(json['date']),
      createdAt: DateTime.parse(json['created_at']),
      currency: Currency.fromStr(json['currency']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(),
      'currency': currency.toStr(),
    };
  }
}