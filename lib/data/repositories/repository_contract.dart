/// Base repository contract for clean architecture data abstraction
abstract class BaseRepository<T> {
  Future<List<T>> getAll();
  Future<T?> getById(String id);
  Future<void> create(T item);
  Future<void> update(T item);
  Future<void> delete(String id);
}
