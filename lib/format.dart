const List<String> _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String shortDate(DateTime value) => '${_months[value.month - 1]} ${value.day}';

String countMeta(DateTime startedAt, int items, int units) =>
    '${shortDate(startedAt)} · $items item${items == 1 ? '' : 's'} '
    '· $units unit${units == 1 ? '' : 's'}';
