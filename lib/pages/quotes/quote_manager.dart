import 'dart:math';

import 'package:zendoro/pages/quotes/quotes.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuoteManager {
  static Future<List<String>> getRemainingQuotes() async {
    final prefs = await SharedPreferences.getInstance();
    final usedQuotes = prefs.getStringList('usedQuotes') ?? [];
    return allQuotes.where((quote) => !usedQuotes.contains(quote)).toList();
  }

  static Future<String> getDailyQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDate = prefs.getString('lastQuoteDate');
    final currentDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // If same day, return stored quote
    if (lastDate == currentDate) {
      return prefs.getString('currentQuote') ?? allQuotes[0];
    }

    // Get remaining quotes
    final remainingQuotes = await getRemainingQuotes();
    String selectedQuote;

    if (remainingQuotes.isEmpty) {
      // Reset if all quotes have been used
      await prefs.remove('usedQuotes');
      selectedQuote = allQuotes[0];
    } else {
      // Select random quote from remaining
      selectedQuote = remainingQuotes[Random().nextInt(remainingQuotes.length)];
    }

    // Save new quote and date
    await prefs.setStringList('usedQuotes', [
      ...(prefs.getStringList('usedQuotes') ?? []),
      selectedQuote,
    ]);
    await prefs.setString('lastQuoteDate', currentDate);
    await prefs.setString('currentQuote', selectedQuote);

    return selectedQuote;
  }
}
