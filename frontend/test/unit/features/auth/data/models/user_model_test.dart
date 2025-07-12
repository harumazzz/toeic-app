import 'package:flutter_test/flutter_test.dart';
import 'package:learn/features/auth/data/models/user_model.dart';

void main() {
  test('UserModel fromJson/toJson', () {
    final json = {'id': 1, 'email': 'a', 'username': 'b'};
    final model = UserModel.fromJson(json);
    expect(model.id, 1);
    expect(model.email, 'a');
    expect(model.username, 'b');
    expect(model.toJson(), json);
  });

  test('UserModel toEntity', () {
    const model = UserModel(id: 1, email: 'a', username: 'b');
    final entity = model.toEntity();
    expect(entity.id, 1);
    expect(entity.email, 'a');
    expect(entity.username, 'b');
  });
}
