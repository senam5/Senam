create or replace view reimbursement_balance as
select venture, count(*) as unreimbursed_count, sum(total_paid) as amount_owed
from expense
where reimbursed = false
  and (deductible is distinct from 'NO')
group by venture;
