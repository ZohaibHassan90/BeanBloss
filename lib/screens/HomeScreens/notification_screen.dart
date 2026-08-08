import 'package:beanbloss/theme/app_colors.dart';
import 'package:beanbloss/widgets/app_buttons.dart';
import 'package:beanbloss/widgets/app_empty_state.dart';
import 'package:beanbloss/widgets/app_page_header.dart';
import 'package:beanbloss/widgets/app_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Opens notifications as a right→left side panel over the current screen.
Future<T?> openNotificationsPanel<T>(BuildContext context) {
  return Navigator.of(context).push<T>(
    _NotificationsPanelRoute<T>(child: const NotificationScreen()),
  );
}

class _NotificationsPanelRoute<T> extends PageRouteBuilder<T> {
  _NotificationsPanelRoute({required Widget child})
      : super(
          opaque: false,
          barrierDismissible: true,
          barrierColor: Colors.black.withOpacity(0.28),
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 340),
          pageBuilder: (context, animation, secondaryAnimation) => child,
        );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    final width = MediaQuery.sizeOf(context).width;
    final panelWidth = width * 0.88;

    return Align(
      alignment: Alignment.centerRight,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.85, end: 1).animate(curved),
          child: SizedBox(
            width: panelWidth,
            height: double.infinity,
            child: child,
          ),
        ),
      ),
    );
  }
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = const ['All', 'Orders', 'Offers', 'Rewards'];

  late List<NotificationItem> _notifications;

  @override
  void initState() {
    super.initState();
    _notifications = _seedNotifications();
  }

  List<NotificationItem> get _filtered {
    var list = List<NotificationItem>.from(_notifications);
    if (_selectedFilter != 'All') {
      final type = switch (_selectedFilter) {
        'Orders' => NotificationType.order,
        'Offers' => NotificationType.promotion,
        'Rewards' => NotificationType.reward,
        _ => null,
      };
      if (type != null) {
        list = list.where((n) => n.type == type).toList();
      }
    }
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markRead(String id) {
    setState(() {
      final i = _notifications.indexWhere((n) => n.id == id);
      if (i != -1) _notifications[i].isRead = true;
    });
    HapticFeedback.selectionClick();
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    HapticFeedback.lightImpact();
  }

  void _delete(String id) {
    setState(() => _notifications.removeWhere((n) => n.id == id));
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryBg,
          borderRadius:
              const BorderRadius.horizontal(left: Radius.circular(28)),
          border: Border(
            left: BorderSide(color: AppColors.border(0.22)),
          ),
        ),
        child: ClipRRect(
          borderRadius:
              const BorderRadius.horizontal(left: Radius.circular(28)),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildFilters(),
                Expanded(
                  child: items.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.notifications_none_rounded,
                          title: 'No notifications',
                          subtitle: 'You\'re all caught up for now.',
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                          itemCount: items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              _buildCard(items[index]),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AppPageHeader(
      title: 'Notifications',
      subtitle: _unreadCount > 0
          ? '$_unreadCount unread update${_unreadCount == 1 ? '' : 's'}'
          : 'You\'re all caught up',
      icon: Icons.notifications_rounded,
      showBack: false,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_unreadCount > 0)
            AppLinkButton(
              label: 'Read all',
              onPressed: _markAllRead,
            ),
          AppIconButton(
            icon: Icons.close_rounded,
            size: 36,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final selected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedFilter = filter);
              HapticFeedback.selectionClick();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryBrown : AppColors.softFill(),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected
                      ? AppColors.primaryBrown
                      : AppColors.border(0.22),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard(NotificationItem item) {
    final meta = _typeMeta(item.type);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _delete(item.id),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: AppColors.destructive.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AppColors.destructive,
        ),
      ),
      child: Material(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(AppRadii.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          onTap: () {
            if (!item.isRead) _markRead(item.id);
            _openDetail(item);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadii.xl),
              border: Border.all(
                color: item.isRead
                    ? AppColors.border(0.18)
                    : AppColors.border(0.55),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: meta.$1.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(meta.$2, color: meta.$1, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textDark,
                                fontSize: 14,
                                fontWeight: item.isRead
                                    ? FontWeight.w600
                                    : FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeLabel(item.timestamp),
                            style: TextStyle(
                              color: AppColors.textLight.withOpacity(0.85),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textLight.withOpacity(0.95),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!item.isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBrown,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail(NotificationItem item) {
    final meta = _typeMeta(item.type);

    showAppSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: meta.$1.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(meta.$2, color: meta.$1, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.message,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              AppPrimaryButton(
                label: 'Done',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  (Color, IconData) _typeMeta(NotificationType type) {
    return switch (type) {
      NotificationType.order => (
          AppColors.primaryBrown,
          Icons.local_cafe_rounded,
        ),
      NotificationType.promotion => (
          AppColors.accentGold,
          Icons.local_offer_outlined,
        ),
      NotificationType.reward => (
          AppColors.lightBrown,
          Icons.star_outline_rounded,
        ),
      NotificationType.system => (
          AppColors.textLight,
          Icons.notifications_none_rounded,
        ),
    };
  }

  String _timeLabel(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}';
  }

  List<NotificationItem> _seedNotifications() {
    final now = DateTime.now();
    return [
      NotificationItem(
        id: '1',
        title: 'Order ready for pickup',
        message: 'Your Caramel Macchiato is ready at BeanBloss.',
        type: NotificationType.order,
        timestamp: now.subtract(const Duration(minutes: 2)),
        isRead: false,
      ),
      NotificationItem(
        id: '2',
        title: 'Flash offer on pastries',
        message: 'Get 30% off pastries today with code PASTRY30.',
        type: NotificationType.promotion,
        timestamp: now.subtract(const Duration(minutes: 18)),
        isRead: false,
      ),
      NotificationItem(
        id: '3',
        title: 'Reward points earned',
        message: 'You earned 50 points. 200 more to your next free drink.',
        type: NotificationType.reward,
        timestamp: now.subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      NotificationItem(
        id: '4',
        title: 'Order is being prepared',
        message: 'Order #ORD-7832 should be ready in about 8 minutes.',
        type: NotificationType.order,
        timestamp: now.subtract(const Duration(hours: 3)),
        isRead: true,
      ),
      NotificationItem(
        id: '5',
        title: 'Seasonal menu is live',
        message: 'Pumpkin Spice Latte and fall favorites are available now.',
        type: NotificationType.promotion,
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      NotificationItem(
        id: '6',
        title: 'Welcome to Gold tier',
        message: 'Enjoy 1.5x points and exclusive member offers.',
        type: NotificationType.reward,
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ];
  }
}

enum NotificationType { order, promotion, reward, system }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.isRead,
  });
}
