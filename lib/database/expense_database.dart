import 'package:expense_tracker_minimal/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class ExpenseDatabase extends ChangeNotifier {
  static late Isar isar;
  // ignore: prefer_final_fields
  List<Expense> _allExpenses = [];

  //init DB
  static Future<void> initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([ExpenseSchema], directory: dir.path);
  }

  //getter for all expenses
  List<Expense> get allExpenses => _allExpenses;

  //operetions

  //create
  Future<void> createNewExpense(Expense newExpense) async {
    await isar.writeTxn(() => isar.expenses.put(newExpense));
    await readExpenses();
  }

  //read
  Future<void> readExpenses() async {
    List<Expense> fetchedExpenses = await isar.expenses.where().findAll();
    _allExpenses.clear();
    _allExpenses.addAll(fetchedExpenses);
    notifyListeners();
  }

  //update
  Future<void> updateExpense(int id, Expense updateExpense) async {
    updateExpense.id = id;
    await isar.writeTxn(() => isar.expenses.put(updateExpense));
    await readExpenses();
  }

  //delete
  Future<void> deleteExpense(int id) async {
    await isar.writeTxn(() => isar.expenses.delete(id));
    await readExpenses();
  }

  Future<Map<int, double>> calculateMonthlyTotal() async {
    await readExpenses();
    Map<int, double> monthlyTotal = {};
    for (var expense in _allExpenses) {
      int month = expense.date.month;
      if (monthlyTotal.containsKey(month)) {
        monthlyTotal[month] = monthlyTotal[month]! + expense.amount;
      }
    }
    return monthlyTotal;
  }

  int getStartMonth() {
    if (_allExpenses.isEmpty) {
      return DateTime.now().month;
    }
    _allExpenses.sort((a, b) => a.date.compareTo(b.date));
    return _allExpenses.first.date.month;
  }

  int getStartYear() {
    if (_allExpenses.isEmpty) {
      return DateTime.now().year;
    }
    _allExpenses.sort((a, b) => a.date.compareTo(b.date));
    return _allExpenses.first.date.year;
  }
}
