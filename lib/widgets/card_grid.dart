class CardGrid extends StatefulWidget {
  final List<TcgCard> cards;
  final int itemsPerPage;

  const CardGrid({
    super.key,
    required this.cards,
    this.itemsPerPage = 30,
  });

  @override
  State<CardGrid> createState() => _CardGridState();
}

class _CardGridState extends State<CardGrid> {
  final _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      setState(() => _currentPage++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedCards = widget.cards.take(widget.itemsPerPage * _currentPage).toList();

    return GridView.builder(
      controller: _scrollController,
      // ...existing code...
      itemCount: displayedCards.length,
      itemBuilder: (context, index) {
        final card = displayedCards[index];
        return Hero(
          tag: card.id,
          child: CardGridItem(card: card),
        );
      },
    );
  }
}
