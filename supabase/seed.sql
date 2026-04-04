-- ============================================================
-- Seed data: Default expense categories
-- ============================================================
INSERT INTO public.categories (name, icon, color) VALUES
  ('Groceries',      'shopping_basket',   '#4CAF50'),
  ('Dining',         'restaurant',        '#FF9800'),
  ('Transport',      'directions_car',    '#2196F3'),
  ('Entertainment',  'movie',             '#9C27B0'),
  ('Shopping',       'shopping_bag',      '#E91E63'),
  ('Utilities',      'bolt',              '#FF5722'),
  ('Rent',           'home',              '#607D8B'),
  ('Healthcare',     'local_hospital',    '#00BCD4'),
  ('Education',      'school',            '#3F51B5'),
  ('Travel',         'flight',            '#009688'),
  ('Subscriptions',  'subscriptions',     '#795548'),
  ('Coffee',         'local_cafe',        '#8D6E63'),
  ('Fuel',           'local_gas_station', '#FF6F00'),
  ('Fitness',        'fitness_center',    '#E040FB'),
  ('Gifts',          'redeem',            '#F44336'),
  ('Insurance',      'shield',            '#546E7A'),
  ('Investments',    'trending_up',       '#00C853'),
  ('Other',          'category',          '#9E9E9E')
ON CONFLICT (name) DO NOTHING;
