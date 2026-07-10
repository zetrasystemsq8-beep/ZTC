import 'package:dartz/dartz.dart';
import 'package:flutter_clean_architecture/core/network/dio_service.dart';
import 'package:flutter_clean_architecture/core/error/failure.dart';
import 'package:flutter_clean_architecture/features/send_receive/data/models/contact_model.dart';
import 'package:flutter_clean_architecture/features/send_receive/data/models/send_receive_response_model.dart';
import 'package:flutter_clean_architecture/features/send_receive/domain/entities/contact.dart';
import 'package:flutter_clean_architecture/features/send_receive/domain/entities/send_receive_response.dart';
import 'package:flutter_clean_architecture/features/send_receive/domain/repositories/send_receive_repository.dart';

typedef FutureEither<T> = Future<Either<Failure, T>>;

class SendReceiveRepositoryImpl implements SendReceiveRepository {
  final DioService _dioService;

  SendReceiveRepositoryImpl(this._dioService);

  @override
  FutureEither<List<Contact>> getContacts() async {
    final result = await _dioService.get('/contacts');
    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as List<dynamic>;
        final contacts = data
            .map((json) => ContactModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return right(contacts);
      },
    );
  }

  @override
  FutureEither<Contact> getContactById({required String contactId}) async {
    final result = await _dioService.get('/contacts/$contactId');
    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as Map<String, dynamic>;
        final contactModel = ContactModel.fromJson(data);
        return right(contactModel);
      },
    );
  }

  @override
  FutureEither<Contact> addContact({
    required String name,
    required String email,
    String? phone,
  }) async {
    final result = await _dioService.post(
      '/contacts',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
      },
    );
    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as Map<String, dynamic>;
        final contactModel = ContactModel.fromJson(data);
        return right(contactModel);
      },
    );
  }

  @override
  FutureEither<SendReceiveResponse> sendMoney({
    required String recipientEmail,
    required double amount,
    String? description,
  }) async {
    final result = await _dioService.post(
      '/transactions/send',
      data: {
        'recipientEmail': recipientEmail,
        'amount': amount,
        'description': description,
      },
    );
    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as Map<String, dynamic>;
        final sendReceiveResponseModel = SendReceiveResponseModel.fromJson(data);
        return right(sendReceiveResponseModel);
      },
    );
  }

  @override
  FutureEither<SendReceiveResponse> requestMoney({
    required String senderEmail,
    required double amount,
    String? description,
  }) async {
    final result = await _dioService.post(
      '/transactions/request',
      data: {
        'senderEmail': senderEmail,
        'amount': amount,
        'description': description,
      },
    );
    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as Map<String, dynamic>;
        final sendReceiveResponseModel = SendReceiveResponseModel.fromJson(data);
        return right(sendReceiveResponseModel);
      },
    );
  }

  @override
  FutureEither<SendReceiveResponse> cancelRequest({required String requestId}) async {
    final result = await _dioService.post(
      '/transactions/request/cancel',
      data: {
        'requestId': requestId,
      },
    );
    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as Map<String, dynamic>;
        final sendReceiveResponseModel = SendReceiveResponseModel.fromJson(data);
        return right(sendReceiveResponseModel);
      },
    );
  }

  @override
  FutureEither<List<Contact>> searchContacts({required String query}) async {
    final result = await _dioService.get(
      '/contacts/search',
      queryParameters: {
        'q': query,
      },
    );
    return result.fold(
      (failure) => left(failure),
      (response) {
        final data = response.data as List<dynamic>;
        final contacts = data
            .map((json) => ContactModel.fromJson(json as Map<String, dynamic>))
            .toList();
        return right(contacts);
      },
    );
  }

  @override
  FutureEither<bool> deleteContact({required String contactId}) async {
    final result = await _dioService.delete('/contacts/$contactId');
    return result.fold(
      (failure) => left(failure),
      (response) {
        return right(true);
      },
    );
  }
}
