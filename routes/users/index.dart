// lib/src/routes/users/index.dart
import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart' show SqliteException;
import 'package:frog_sqlite/src/database/database.dart'; // Import your generated database

FutureOr<Response> onRequest(RequestContext context) async {
  final db = context.read<AppDatabase>(); // Read the AppDatabase instance

  switch (context.request.method) {
    case HttpMethod.get:
      return _getUsers(context, db);
    case HttpMethod.post:
      return _createUser(context, db);
    default:
      return Response.json(
        statusCode: HttpStatus.methodNotAllowed,
        body: {'message': 'Method Not Allowed'},
      );
  }
}

/// GET /users
Future<Response> _getUsers(RequestContext context, AppDatabase db) async {
  final users = await db.getAllUsers(); // Use Drift's generated method
  final userList =
      users.map((user) => user.toJson()).toList(); // Convert to JSON
  return Response.json(body: userList);
}

/// POST /users
Future<Response> _createUser(RequestContext context, AppDatabase db) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final name = body['name'] as String?;
  final email = body['email'] as String?;

  if (name == null || email == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'message': 'Name and email are required.'},
    );
  }

  try {
    final id = await db.createUser(UsersCompanion(
      name: Value(name), // Use Value for inserts/updates
      email: Value(email),
    ));
    return Response.json(
      statusCode: HttpStatus.created,
      body: {
        'message': 'User created successfully.',
        'id': id,
        'name': name,
        'email': email
      },
    );
  } on SqliteException catch (e) {
    if (e.message.contains('UNIQUE constraint failed')) {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {'message': 'User with this email already exists.'},
      );
    }
    rethrow;
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'message': 'Failed to create user: $e'},
    );
  }
}
