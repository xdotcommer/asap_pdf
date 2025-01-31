Kaminari.configure do |config|
  config.default_per_page = 25
  config.window = 2        # Shows 2 pages on each side of current page
  config.outer_window = 1  # Shows 1 page at the beginning and end
  config.left = 1         # Shows 1 page to the left
  config.right = 1        # Shows 1 page to the right
end
