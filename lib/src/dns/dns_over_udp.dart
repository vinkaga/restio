// Copyright 2019 Gohilla.com team.
// Modifications Copyright 2019 Tiago Melo.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:ip/ip.dart';
import 'package:meta/meta.dart';
import 'package:raw/raw.dart';
import 'package:restio/src/dns/dns.dart';
import 'package:restio/src/dns/dns_packet.dart';

class DnsOverUdp extends PacketBasedDns {
  static final _portRandom = Random.secure();
  final InternetAddress remoteAddress;
  final int remotePort;
  final InternetAddress localAddress;
  final int localPort;
  final Duration timeout;
  Future<RawDatagramSocket> _socket;

  final _responseWaiters = LinkedList<_DnsResponseWaiter>();

  DnsOverUdp({
    @required this.remoteAddress,
    this.remotePort = 53,
    this.localAddress,
    this.localPort,
    this.timeout,
  }) {
    if (remoteAddress == null) {
      throw ArgumentError.notNull('remoteAddress');
    }
    if (remotePort == null) {
      throw ArgumentError.notNull('remotePort');
    }
  }

  factory DnsOverUdp.ip(String ip) {
    return DnsOverUdp(remoteAddress: InternetAddress(ip));
  }

  factory DnsOverUdp.google() {
    return DnsOverUdp.ip('8.8.8.8');
  }

  factory DnsOverUdp.cloudflare() {
    return DnsOverUdp.ip('1.1.1.1');
  }

  factory DnsOverUdp.openDns() {
    return DnsOverUdp.ip('208.67.222.222');
  }

  factory DnsOverUdp.norton() {
    return DnsOverUdp.ip('199.85.126.10');
  }

  factory DnsOverUdp.comodo() {
    return DnsOverUdp.ip('8.26.56.26');
  }

  @override
  Future<DnsPacket> lookupPacket(
    String host, {
    InternetAddressType type = InternetAddressType.any,
  }) async {
    final socket = await _getSocket();
    final dnsPacket = DnsPacket();
    dnsPacket.questions = [DnsQuestion(host: host)];

    // Add query to list of unfinished queries.
    final responseWaiter = _DnsResponseWaiter(host);
    _responseWaiters.add(responseWaiter);

    // Send query.
    socket.send(
      dnsPacket.toImmutableBytes(),
      remoteAddress,
      remotePort,
    );

    // Get timeout for response.
    final timeout = this.timeout ?? Dns.defaultTimeout;

    // Set timer.
    responseWaiter.timer = Timer(timeout, () {
      // Ignore if already completed.
      if (responseWaiter.completer.isCompleted) {
        return;
      }

      // Remove from the list of response waiters
      responseWaiter.unlink();

      // Complete the future
      responseWaiter.completer.completeError(
        TimeoutException("DNS query '$host' timeout"),
      );
    });

    // Return future
    return responseWaiter.completer.future;
  }

  Future<RawDatagramSocket> _getSocket() async {
    if (_socket != null) {
      return _socket;
    }

    final socket = await _bindSocket(localAddress, localPort);

    socket.listen((event) {
      if (event == RawSocketEvent.read) {
        // Read UDP packet.
        final datagram = socket.receive();

        if (datagram == null) {
          return;
        }

        _receiveUdpPacket(datagram);
      }
    });

    return socket;
  }

  void _receiveUdpPacket(Datagram datagram) {
    // Read DNS packet.
    final dnsPacket = DnsPacket();
    dnsPacket.decodeSelf(RawReader.withBytes(datagram.data));

    // Read answers.
    for (var answer in dnsPacket.answers) {
      final host = answer.name;
      final removedResponseWaiters = <_DnsResponseWaiter>[];

      for (var query in _responseWaiters) {
        if (query.completer.isCompleted == false && query.host == host) {
          removedResponseWaiters.add(query);
          query.timer.cancel();
          query.completer.complete(dnsPacket);
          break;
        }
      }

      for (var removed in removedResponseWaiters) {
        removed.unlink();
      }
    }
  }

  static Future<RawDatagramSocket> _bindSocket(
    InternetAddress address,
    int port,
  ) async {
    address ??= InternetAddress.anyIPv4;

    for (var n = 3; n > 0; n--) {
      try {
        return await RawDatagramSocket.bind(address, port ?? _randomPort());
      } catch (e) {
        if (port == null && n > 1 && e.toString().contains('port')) {
          return null;
        }
        rethrow;
      }
    }

    throw StateError('impossible state');
  }

  static int _randomPort() {
    const min = 10000;
    return min + _portRandom.nextInt((1 << 16) - min);
  }
}

class _DnsResponseWaiter extends LinkedListEntry<_DnsResponseWaiter> {
  final String host;
  final Completer<DnsPacket> completer = Completer<DnsPacket>();
  Timer timer;
  final List<IpAddress> result = <IpAddress>[];

  _DnsResponseWaiter(this.host);
}
