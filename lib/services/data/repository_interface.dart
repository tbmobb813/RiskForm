abstract class RepositoryInterface<T> {
  Future<List<T>> listAll();
  Future<T?> getById(String id);
  Future<void> save(T item);
}
