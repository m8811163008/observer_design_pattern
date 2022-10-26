import 'dart:async';
import 'dart:math';

import 'package:faker/faker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Used as a base for all the specific stock ticker classes.
abstract class StockTicker {
  /// A title to show on UI for selecting by a user
  late final String title;

  /// Periodically emits a new stock value that is stored
  /// in the stock property by using the [setStock()] method.
  late final Timer stockTimer;

  /// Store last stock information.
  @protected
  Stock? stock;
  final _subscribers = <StockSubscriber>[];

  /// Add a new stock subscriber.
  void subscribe(StockSubscriber subscriber) => _subscribers.add(subscriber);

  /// Remove a new stock subscriber.
  void unsubscribe(StockSubscriber subscriber) =>
      _subscribers.removeWhere((s) => s.id == subscriber.id);

  /// Notifies subscribers about the stock change.
  void notifySubscribers() {
    _subscribers.forEach(_updateElement);
  }

  void _updateElement(StockSubscriber subscriber) {
    if (stock != null) {
      subscriber.update(stock!);
    }
  }

  /// Sets stock value.
  void setStock(StockTickerSymbol stockTickerSymbol, int min, int max) {
    final lastStock = stock;
    final price = Random().nextInt(max) + min / 100;
    final changeAmount = lastStock != null ? price - lastStock.price : 0.0;
    stock = Stock(
      symbol: stockTickerSymbol,
      changeDirection: changeAmount >= 0
          ? StockChangeDirection.growing
          : StockChangeDirection.falling,
      price: price,
      changeAmount: changeAmount.abs(),
    );
  }

  /// Stops ticker emitting stock events.
  void stopTicker() {
    stockTimer.cancel();
  }
}

class GameStopStockTicker extends StockTicker {
  GameStopStockTicker() {
    title = StockTickerSymbol.GME.toShortString();
    stockTimer = Timer.periodic(
      const Duration(seconds: 2),
      (timer) {
        setStock(StockTickerSymbol.GME, 16000, 22000);
        notifySubscribers();
      },
    );
  }
}

class GoogleStockTicker extends StockTicker {
  GoogleStockTicker() {
    title = StockTickerSymbol.GOOGL.toShortString();
    stockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      print(timer.toString());
      setStock(StockTickerSymbol.GOOGL, 200000, 204000);
      notifySubscribers();
    });
  }
}

class TeslaStockTicker extends StockTicker {
  TeslaStockTicker() {
    title = StockTickerSymbol.GOOGL.toShortString();
    stockTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      print('tesla ticker $timer');
      setStock(StockTickerSymbol.TSLA, 60000, 65000);
      notifySubscribers();
    });
  }
}

extension StockTickerSymbolExtension on StockTickerSymbol {
  String toShortString() => toString().split('.').last;
}

/// To store info about the stock.
class Stock {
  StockTickerSymbol symbol;
  StockChangeDirection changeDirection;
  double price;
  double changeAmount;

  Stock({
    required this.symbol,
    required this.changeDirection,
    required this.price,
    required this.changeAmount,
  });

  static empty() => Stock(
        symbol: StockTickerSymbol.GME,
        changeDirection: StockChangeDirection.growing,
        price: 0,
        changeAmount: 0,
      );
}

enum StockTickerSymbol { GME, GOOGL, TSLA }

enum StockChangeDirection { growing, falling }

/// [StockSubscriber] is an abstract class that is used as a
/// base class for all the specific stock subscriber classes.
abstract class StockSubscriber {
  late final String title;
  final id = faker.guid.guid();

  @protected
  StreamController<Stock> streamController = StreamController.broadcast();

  Stream<Stock> get stockStream => streamController.stream;

  void update(Stock stock);
}

class DefaultStockSubscriber extends StockSubscriber {
  DefaultStockSubscriber() {
    title = 'All stocks';
  }

  @override
  void update(Stock stock) {
    streamController.add(stock);
  }
}

class GrowingStockSubscriber extends StockSubscriber {
  GrowingStockSubscriber() {
    title = 'Growing stocks';
  }

  @override
  void update(Stock stock) {
    if (stock.changeDirection == StockChangeDirection.growing) {
      streamController.add(stock);
    }
  }
}

/// [ObserverExample] contains a list of [StockSubscriber] as
/// well as a list of [StockTicker] model objects( specific
/// [StockTickerModel] class with a flag of whether the user is
/// subscribe to the stock ticker or not.
class ObserverExample extends StatefulWidget {
  const ObserverExample({Key? key}) : super(key: key);

  @override
  State<ObserverExample> createState() => _ObserverExampleState();
}

class _ObserverExampleState extends State<ObserverExample> {
  final _stockSubscriberList = <StockSubscriber>[
    DefaultStockSubscriber(),
    GrowingStockSubscriber(),
  ];

  final _stockTickerModelsList = <StockTickerModel>[
    StockTickerModel(stockTicker: GoogleStockTicker()),
    StockTickerModel(stockTicker: TeslaStockTicker()),
    StockTickerModel(stockTicker: GameStopStockTicker()),
  ];
  final _stockEntries = <Stock>[];
  StreamSubscription<Stock>? _stockStreamSubscription;
  StockSubscriber _subscriber = DefaultStockSubscriber();
  int _selectedSubscriberIndex = 0;

  @override
  void initState() {
    super.initState();
    _stockStreamSubscription = _subscriber.stockStream.listen(_onStockChange);
  }

  @override
  void dispose() {
    for (final ticker in _stockTickerModelsList) {
      ticker.stockTicker.stopTicker();
    }
    _stockStreamSubscription?.cancel();
    super.dispose();
  }

  void _onStockChange(Stock stock) {
    setState(() {
      _stockEntries.add(stock);
    });
  }

  void _setSelectedSubscriberIndex(int? index) {
    for (final ticker in _stockTickerModelsList) {
      if (ticker.subscribe) {
        ticker.toggleSubscribed();
        ticker.stockTicker.unsubscribe(_subscriber);
      }
    }

    _stockStreamSubscription?.cancel();

    setState(() {
      _stockEntries.clear();
      _selectedSubscriberIndex = index!;
      _subscriber = _stockSubscriberList[_selectedSubscriberIndex];
      _stockStreamSubscription = _subscriber.stockStream.listen(_onStockChange);
    });
  }

  void _toggleStockTickerSelection(int index) {
    final stockTickerModel = _stockTickerModelsList[index];
    final stockTicker = stockTickerModel.stockTicker;

    if (stockTickerModel.subscribe) {
      stockTicker.unsubscribe(_subscriber);
    } else {
      stockTicker.subscribe(_subscriber);
    }
    setState(() {
      stockTickerModel.toggleSubscribed();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: const ScrollBehavior(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Column(
          children: <Widget>[
            StockSubscriberSelection(
              stockSubscriberList: _stockSubscriberList,
              selectedIndex: _selectedSubscriberIndex,
              onChanged: _setSelectedSubscriberIndex,
            ),
            StockTickerSelection(
                stockTickers: _stockTickerModelsList,
                onChanged: _toggleStockTickerSelection),
            Column(
              children: [
                for (final stock in _stockEntries.reversed)
                  StockRow(stock: stock)
              ],
            )
          ],
        ),
      ),
    );
  }
}

class StockTickerModel {
  final StockTicker stockTicker;
  bool subscribe = false;

  StockTickerModel({required this.stockTicker});

  void toggleSubscribed() {
    subscribe = !subscribe;
  }
}

class StockRow extends StatelessWidget {
  final Stock stock;

  const StockRow({Key? key, required this.stock}) : super(key: key);

  Color get color => stock.changeDirection == StockChangeDirection.growing
      ? Colors.green
      : Colors.red;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            stock.symbol.toShortString(),
            style: TextStyle(color: color),
          ),
        ),
        const SizedBox(width: 12.0),
        SizedBox(
          width: 52.0,
          child: Text(
            stock.price.toString(),
            style: TextStyle(color: color),
            textAlign: TextAlign.end,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
          ),
          child: Icon(
            stock.changeDirection == StockChangeDirection.growing
                ? Icons.arrow_upward
                : Icons.arrow_downward,
            color: color,
          ),
        ),
        Text(
          stock.changeAmount.toStringAsFixed(2),
          style: TextStyle(color: color),
        ),
      ],
    );
  }
}

class StockSubscriberSelection extends StatelessWidget {
  final List<StockSubscriber> stockSubscriberList;
  final int selectedIndex;
  final ValueSetter<int?> onChanged;

  const StockSubscriberSelection({
    super.key,
    required this.stockSubscriberList,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        for (var i = 0; i < stockSubscriberList.length; i++)
          RadioListTile(
            value: i,
            groupValue: selectedIndex,
            onChanged: onChanged,
            title: Text(stockSubscriberList[i].title),
            selected: i == selectedIndex,
            activeColor: Colors.black,
          ),
      ],
    );
  }
}

class StockTickerSelection extends StatelessWidget {
  final List<StockTickerModel> stockTickers;
  final ValueChanged<int> onChanged;

  const StockTickerSelection({
    required this.stockTickers,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 700,
      child: Row(
        children: <Widget>[
          for (var i = 0; i < stockTickers.length; i++)
            Expanded(
              child: _TickerTile(
                stockTickerModel: stockTickers[i],
                index: i,
                onChanged: onChanged,
              ),
            )
        ],
      ),
    );
  }
}

class _TickerTile extends StatelessWidget {
  final StockTickerModel stockTickerModel;
  final int index;
  final ValueChanged<int> onChanged;

  const _TickerTile({
    required this.stockTickerModel,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: stockTickerModel.subscribe ? Colors.black : Colors.white,
      child: InkWell(
        onTap: () => onChanged(index),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            stockTickerModel.stockTicker.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: stockTickerModel.subscribe ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: ObserverExample(),
      ),
    ),
  );
}
