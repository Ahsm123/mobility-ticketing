select b.id
from baseline_snapshot as b
         left join  tickets on tickets.id = b.id
         left join products on products.id = tickets.product_id
where b.price is distinct from tickets.price
   or b.currency is distinct from tickets.currency
   or b.product_code is distinct from products.code