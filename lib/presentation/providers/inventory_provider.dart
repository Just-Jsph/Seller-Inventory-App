import 'package:flutter/foundation.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/inventory_transaction_model.dart';
import '../../data/services/inventory_service.dart';

class InventoryProvider extends ChangeNotifier {
  final InventoryService _inventoryService;

  List<ProductModel> _products = [];
  List<CategoryModel> _categories = [];
  List<InventoryTransactionModel> _transactions = [];
  InventorySummary _summary = InventorySummary.empty();

  bool _isLoading = false;
  String? _errorMessage;

  // Active Filter States
  String _searchQuery = '';
  int? _selectedCategoryId;
  StockFilter _stockFilter = StockFilter.all;
  String _selectedTransactionType = 'ALL';

  InventoryProvider({InventoryService? inventoryService})
      : _inventoryService = inventoryService ?? InventoryService();

  // Getters
  List<ProductModel> get products => _products;
  List<CategoryModel> get categories => _categories;
  List<InventoryTransactionModel> get transactions => _transactions;
  InventorySummary get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  int? get selectedCategoryId => _selectedCategoryId;
  StockFilter get stockFilter => _stockFilter;
  String get selectedTransactionType => _selectedTransactionType;

  /// Load all inventory products, categories, summary, and transaction logs for the user
  Future<void> loadData(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _inventoryService.getProducts(
          userId,
          query: _searchQuery,
          categoryId: _selectedCategoryId,
          filter: _stockFilter,
        ),
        _inventoryService.getCategories(userId),
        _inventoryService.getInventorySummary(userId),
        _inventoryService.getTransactions(
          userId,
          transactionType: _selectedTransactionType,
        ),
      ]);

      _products = results[0] as List<ProductModel>;
      _categories = results[1] as List<CategoryModel>;
      _summary = results[2] as InventorySummary;
      _transactions = results[3] as List<InventoryTransactionModel>;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update Search Query and reload products
  Future<void> setSearchQuery(String query, int userId) async {
    _searchQuery = query;
    await _refreshProducts(userId);
  }

  /// Update Category Filter and reload products
  Future<void> setCategoryFilter(int? categoryId, int userId) async {
    _selectedCategoryId = categoryId;
    await _refreshProducts(userId);
  }

  /// Update Stock Level Filter and reload products
  Future<void> setStockFilter(StockFilter filter, int userId) async {
    _stockFilter = filter;
    await _refreshProducts(userId);
  }

  /// Update Transaction Type Filter and reload history
  Future<void> setTransactionTypeFilter(String type, int userId) async {
    _selectedTransactionType = type;
    await _refreshTransactions(userId);
  }

  /// Helper to reload products and summary
  Future<void> _refreshProducts(int userId) async {
    try {
      _products = await _inventoryService.getProducts(
        userId,
        query: _searchQuery,
        categoryId: _selectedCategoryId,
        filter: _stockFilter,
      );
      _summary = await _inventoryService.getInventorySummary(userId);
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Helper to reload transactions
  Future<void> _refreshTransactions(int userId) async {
    try {
      _transactions = await _inventoryService.getTransactions(
        userId,
        transactionType: _selectedTransactionType,
      );
    } catch (e) {
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  /// Add a new product with initial stock
  Future<bool> addProduct({
    required ProductModel product,
    double initialStock = 0.0,
    String? note,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _inventoryService.addProduct(
        product: product,
        initialStock: initialStock,
        note: note,
      );
      await loadData(product.userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update existing product
  Future<bool> updateProduct(ProductModel product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _inventoryService.updateProduct(product);
      await loadData(product.userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Restock product with audit movement
  Future<bool> restockProduct({
    required int userId,
    required int productId,
    required double quantity,
    required int unitCostCents,
    String? note,
    String? referenceId,
    DateTime? date,
    bool updateProductCostPrice = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _inventoryService.restockProduct(
        userId: userId,
        productId: productId,
        quantity: quantity,
        unitCostCents: unitCostCents,
        note: note,
        referenceId: referenceId,
        date: date,
        updateProductCostPrice: updateProductCostPrice,
      );
      await loadData(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Adjust stock level with reason
  Future<bool> adjustStock({
    required int userId,
    required int productId,
    required double newQuantity,
    required String reason,
    int? unitCostCents,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _inventoryService.adjustStock(
        userId: userId,
        productId: productId,
        newQuantity: newQuantity,
        reason: reason,
        unitCostCents: unitCostCents,
      );
      await loadData(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Check if product can be deleted
  Future<CanDeleteResult> canDeleteProduct(int userId, int productId) async {
    return await _inventoryService.canDeleteProduct(userId, productId);
  }

  /// Delete product if safety rules pass
  Future<bool> deleteProduct(int userId, int productId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _inventoryService.deleteProduct(userId, productId);
      await loadData(userId);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Add category
  Future<CategoryModel?> addCategory(int userId, String name, {String? description}) async {
    try {
      final category = await _inventoryService.addCategory(userId, name, description: description);
      _categories = await _inventoryService.getCategories(userId);
      notifyListeners();
      return category;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  /// Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
