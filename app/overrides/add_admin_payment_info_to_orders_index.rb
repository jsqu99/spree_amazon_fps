Deface::Override.new(
  :virtual_path => "spree/admin/orders/index",
  :name => "amazon_fps_admin_capture_1",
  :insert_before => '[data-hook="admin_orders_index_header_actions"]',
  :text => "<th><%= t(:amazon_fps_status) %></th>")

Deface::Override.new(
  :virtual_path => "spree/admin/orders/index",
  :name => "amazon_fps_admin_capture_2",
  :insert_before => "[data-hook='admin_orders_index_row_actions']",
  :partial => "spree/admin/shared/amazon_fps_status")
