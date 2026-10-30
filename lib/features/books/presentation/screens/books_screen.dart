import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/models/book.dart';
import '../../../../core/widgets/settings_sheet.dart';
import '../../../../core/widgets/status_view.dart';
import '../../../bookmarks/presentation/screens/bookmarks_screen.dart';
import '../../../chapters/presentation/screens/chapters_screen.dart';
import '../../../search/presentation/screens/search_screen.dart';
import '../cubit/books_cubit.dart';
import '../widgets/book_tile.dart';

/// Home screen: the list of bundled collections.
class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BooksCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bayan Sunnah · بيان السنة'),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Bookmarks',
            icon: const Icon(Icons.bookmark_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const BookmarksScreen()),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () => showSettingsSheet(context),
          ),
        ],
      ),
      body: BlocBuilder<BooksCubit, BooksState>(
        builder: (context, state) {
          switch (state.status) {
            case BooksStatus.initial:
            case BooksStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case BooksStatus.failure:
              return StatusView(
                icon: Icons.error_outline_rounded,
                message: 'Could not open the library',
                detail: state.errorMessage,
                onRetry: () => context.read<BooksCubit>().load(),
              );
            case BooksStatus.success:
              if (state.books.isEmpty) {
                return const StatusView(
                  icon: Icons.menu_book_rounded,
                  message: 'No collections available',
                );
              }
              return _bookList(state.books);
          }
        },
      ),
    );
  }

  Widget _bookList(List<Book> books) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: books.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final book = books[index];
        return BookTile(
          book: book,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChaptersScreen(book: book),
            ),
          ),
        );
      },
    );
  }
}
