/*CREATE TABLE installment_plan
(
contract_number int NOT NULL,
client_id int NOT NULL,
phone_id int NOT NULL,
color_id tinyint NOT NULL,
merchant_id tinyint NOT NULL,
price numeric(10, 2) NULL,
date_purch date NULL,
qu_inst int NOT NULL,
inst int NULL
)*/
-- select * from installment_plan
/*CREATE TABLE payments
(
merchant_id tinyint NOT NULL,
contract_number int NOT NULL,
date_payment date NULL,
payment int NULL
)*/
--select * from payments



declare @c_id int -- variable for installment contract number
declare @m_id tinyint -- variable for merchant ID

set @c_id=227
set @m_id=67


-----------REPORT 1.1 - query fetching installment contract data -------------

/*select i.merchant_id as 'Merchant ID'
, i.contract_number as 'installment contract number'
, m.merchant_name as 'Merchant name'
, c.client_name as 'Client name'
, b.Brand_name as 'Brand name' 
, p.phone_name as 'Phone name'
, cl.color_name as 'Color'
, i.qu_inst as 'Number of months under the terms of the installment contract' 
, i.inst as 'The amount of one monthly installment (UAH) under the terms of the installment contract' 
, convert (nvarchar, i.date_purch, 104) as 'Date of purchase (Date of the first payment)' 
, case when DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30)) >= i.qu_inst 
	then i.qu_inst
	else DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30))+1
end
as 'The number of monthly installments that must be paid on the last day of the reporting month' 
, i.inst*(case when DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30)) >= i.qu_inst 
	then i.qu_inst
	else DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30))+1
end) as 'Amount (UAH) of monthly installments to be paid on the last day of the reporting month'
from installment_plan i 
join merchants m on i.merchant_id = m.merchant_id 
join clients c on i.client_id=c.client_id
join phones p on p.phone_id=i.phone_id
join brands b on b.brand_id=p.brand_id
join colors cl on cl.color_id=i.color_id
where i.merchant_id=@m_id and i.contract_number=@c_id */--  REPORT 1.1 - query fetching installment contract data (the end)





--------------------REPORT 1.2 - a query that selects payments data under an installment contract---------------
/*declare @scedule_payment TABLE (m_id tinyint, c_id int, year_p int, month_p int, amount int)
declare @year_p int
declare @month_p int
declare @q_pl tinyint
declare @amount int

set @q_pl=1

if (select max(datediff(mm, i.date_purch,p.date_payment)+1) from installment_plan i 
join payments p on i.contract_number=p.contract_number and i.merchant_id=p.merchant_id
where i.merchant_id=@m_id and i.contract_number=@c_id) < (select i.qu_inst 	from  installment_plan i 
	where i.merchant_id=@m_id and i.contract_number=@c_id)
begin

	while @q_pl <= (
		select 	i.qu_inst  from  installment_plan i 
		where i.merchant_id=@m_id and i.contract_number=@c_id)
		
	begin 
				set @year_p=(select year(dateadd(mm,@q_pl-1, i.date_purch)) from  
					installment_plan i 
					where i.merchant_id=@m_id and i.contract_number=@c_id)
			
				set @month_p=(select month(dateadd(mm,@q_pl-1,i.date_purch)) from  
					installment_plan i 
					where i.merchant_id=@m_id and i.contract_number=@c_id)
			
		
		 if (select a.q from (select year (p.date_payment) as y, month (p.date_payment) as m, count (datefromparts (year (p.date_payment), month (p.date_payment),1)) as q 
				    from payments p where p.contract_number=@c_id and p.merchant_id=@m_id
				    group by year (p.date_payment), month (p.date_payment) ) a where y=@year_p and m=@month_p ) > 1
				   begin
						set @amount=(select i.inst from  installment_plan i where i.merchant_id=@m_id and i.contract_number=@c_id)/(select a.q from (select year (p.date_payment) as y, month (p.date_payment) as m, count (datefromparts (year (p.date_payment), month (p.date_payment),1)) as q 
				                    from payments p where p.contract_number=@c_id and p.merchant_id=@m_id
				                    group by year (p.date_payment), month (p.date_payment) ) a where y=@year_p and m=@month_p )
				   end

		else
			begin 
				set @amount=(select i.inst	from  
				installment_plan i 
				where i.merchant_id=@m_id and i.contract_number=@c_id)
			end
		insert into @scedule_payment (m_id, c_id, year_p, month_p, amount) values (@m_id, @c_id, @year_p, @month_p, @amount)
		set @q_pl=@q_pl+1
	end

	select s.m_id as 'Merchant ID'
	, s.c_id as 'Installment contract number'
	, s.year_p as 'Year of installment payment'
	, s.month_p as 'Installment payment month'
	, s.amount as 'The amount of the monthly installment (UAH) under the terms of the installment contract'
	, isnull(convert (nvarchar,p.date_payment, 104),'') as 'Customer payment date'
	, isnull (p.payment,0) as 'Amount paid by the customer'
	
	from @scedule_payment s 
	left join payments p on s.c_id=p.contract_number and s.m_id=p.merchant_id and s.year_p=year(p.date_payment) and s.month_p=month(p.date_payment)
	left join installment_plan i on s.c_id=i.contract_number and s.m_id=i.merchant_id
	where eomonth (DATEFROMPARTS(s.year_p,s.month_p,01)) <  DATEFROMPARTS(2020,05,01)
	order by p.date_payment
end

else
begin
	while @q_pl <= (select max(datediff(mm, i.date_purch,p.date_payment)+1) from installment_plan i 
					join payments p on i.contract_number=p.contract_number and i.merchant_id=p.merchant_id
					where i.merchant_id=@m_id and i.contract_number=@c_id)

begin 
		set @year_p=(select year(dateadd(mm,@q_pl-1, i.date_purch)) from  
			installment_plan i 
			where i.merchant_id=@m_id and i.contract_number=@c_id)
		set @month_p=(select month(dateadd(mm,@q_pl-1,i.date_purch)) from  
			installment_plan i 
			where i.merchant_id=@m_id and i.contract_number=@c_id)
		
		if (@q_pl <= (select i.qu_inst  from  installment_plan i where i.merchant_id=@m_id and i.contract_number=@c_id)) 
		  
		  begin 
			if (select a.q from (select year (p.date_payment) as y, month (p.date_payment) as m, count (datefromparts (year (p.date_payment), month (p.date_payment),1)) as q 
				from payments p where p.contract_number=@c_id and p.merchant_id=@m_id
				group by year (p.date_payment), month (p.date_payment) ) a where y=@year_p and m=@month_p ) <=1
				or 
			(select isnull (sum (p.payment),0) from payments p 
			where p.contract_number=@c_id and p.merchant_id=@m_id and year (p.date_payment)=@year_p and month (p.date_payment)=@month_p)=0

				
				begin
					set @amount=(select i.inst from  installment_plan i where i.merchant_id=@m_id and i.contract_number=@c_id)
				end
			else
				 if (select a.q from (select year (p.date_payment) as y, month (p.date_payment) as m, count (datefromparts (year (p.date_payment), month (p.date_payment),1)) as q 
				    from payments p where p.contract_number=@c_id and p.merchant_id=@m_id
				    group by year (p.date_payment), month (p.date_payment) ) a where y=@year_p and m=@month_p ) > 1
				   begin
						set @amount=(select i.inst from  installment_plan i where i.merchant_id=@m_id and i.contract_number=@c_id)/(select a.q from (select year (p.date_payment) as y, month (p.date_payment) as m, count (datefromparts (year (p.date_payment), month (p.date_payment),1)) as q 
				                    from payments p where p.contract_number=@c_id and p.merchant_id=@m_id
				                    group by year (p.date_payment), month (p.date_payment) ) a where y=@year_p and m=@month_p )
				   end
			
		   end
		else
						
				begin 
					set @amount=0
				end
	
		insert into @scedule_payment (m_id, c_id, year_p, month_p, amount) values (@m_id, @c_id, @year_p, @month_p, @amount)
		set @q_pl=@q_pl+1
end
	select s.m_id as 'Merchant ID'
	, s.c_id as 'Installment contract number'
	, s.year_p as 'Year of installment payment'
	, s.month_p as 'Installment payment month'
	, s.amount  as 'The amount of the monthly installment (UAH) under the terms of the installment contract'
	, isnull(convert (nvarchar,p.date_payment, 104),'') as 'Customer payment date'
	, isnull (p.payment,0) as 'Amount paid by the customer'
	from @scedule_payment s
	left join payments p on s.c_id=p.contract_number and s.m_id=p.merchant_id and s.year_p=year(p.date_payment) and s.month_p=month(p.date_payment)
	left join installment_plan i on s.c_id=i.contract_number and s.m_id=i.merchant_id
	where eomonth (DATEFROMPARTS(s.year_p,s.month_p,01)) <  DATEFROMPARTS(2020,05,01)
	order by s.month_p
end  */ --  REPORT 1.2 - a query that selects data on payments under an installment contract (the end)



-----------REPORT 1.3 - a query that selects total data on payments under an installment contract------------

/*declare @contract_payment TABLE (m_id tinyint, c_id int, c_payment int, s_payment int, o_total int, z_payment int)
declare @c_payment int
declare @s_payment int
declare @o_total int
declare @z_payment int

set @c_payment= (select installment_plan.qu_inst*installment_plan.inst from installment_plan where installment_plan.contract_number=@c_id and installment_plan.merchant_id=@m_id)

set @s_payment= (select SUM (payments.payment) from payments where payments.contract_number=@c_id and payments.merchant_id=@m_id)

set @o_total= @c_payment - @s_payment

set @z_payment = (select i.inst*(case when DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30)) >= i.qu_inst 
										then i.qu_inst
										else DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30))+1
										end) 
							as 'Amount (UAH) of monthly installments to be paid on the last day of the reporting month'
					from installment_plan i 
					where i.merchant_id=@m_id and i.contract_number=@c_id) - @s_payment

insert into @contract_payment (m_id, c_id, c_payment, s_payment, o_total, z_payment) values (@m_id, @c_id, @c_payment, @s_payment, @o_total, @z_payment)
select c.m_id as 'Merchant ID'
, c.c_id as 'Installment contract number'
, c.c_payment as 'Amount (UAH) of monthly fees to be paid (total)'
, c.s_payment as 'Amount paid by the customer'
, c.o_total as 'Total installment contract balance'
, z_payment as 'Arrears due to underpayments or missed monthly installments' 
from @contract_payment c */ --  REPORT 1.3 - a query that selects total data on payments under an installment contract (the end)





---------------REPORT 2 Summary debt data for all installment contracts  ------------------
/*select 
y.pr as 'installment period'
, y.nz as 'The presence of debt'
, sum (y.sr) as 'Installment amount'
, sum (y.spl) as 'Amount to be paid at the end of the reporting month'
, sum (y.fact) as 'Amount paid at the end of the reporting month'
, count (y.sr) as 'number of clients'
, sum (y.spl)- sum (y.fact) as 'Debt'
, sum (y.ost_rassr) as 'Installment balance excluding debt'
, sum (y.pr0) as 'Number of customers who are past due 0 monthly payments'
, sum (y.pr1) as 'Number of customers who are past due 1 monthly payment'
, sum (y.pr2) as 'Number of customers who are past due 2 monthly payments'
, sum (y.pr3) as 'Number of customers who are past due 3 monthly payments'
, sum (y.pr4) as 'Number of customers who are past due 4 or more monthly payments'
, sum (y.z0) as 'The amount of debt from customers who are overdue with 0 monthly payments'
, sum (y.z1) as 'The amount of debt from customers who are overdue with 1 monthly payment'
, sum (y.z2) as 'The amount of debt from customers who are overdue with 2 monthly payments'
, sum (y.z3) as 'The amount of debt from customers who are overdue with 3 monthly payments'
, sum (y.z4) as 'The amount of debt from customers who are overdue with 4 or more monthly payments'

from 
(select 
case when x.d_p  >= x.q_c
	then 'Finished'
	else 'Not finished' 
	end as pr -- 'installment period'
, case when (x.fact<x.plan_s)
		then 'Have a debt'
		else 'No debt'
	end as 	nz -- 'The presence of debt'
, x.r as sr --	'Installment amount'
, x.plan_s as 	spl -- 'Amount to be paid at the end of the reporting month'
, x.fact as fact --'Amount of payments, actual'
, x.ost_r as ost_rassr
, x.kol_prop as q_m
, case when x.kol_prop=0
		then 1
		else 0
		end as pr0
, case when x.kol_prop=1
		then 1
		else 0
		end as pr1
, case when x.kol_prop=2
		then 1
		else 0
		end as pr2
, case when x.kol_prop=3
		then 1
		else 0
		end as pr3
, case when x.kol_prop>3
		then 1
		else 0
		end as pr4
, case when x.kol_prop=0
		then x.plan_s-x.fact
		else 0
		end as z0
, case when x.kol_prop=1
		then x.plan_s-x.fact
		else 0
		end as z1
, case when x.kol_prop=2
		then x.plan_s-x.fact
		else 0
		end as z2
, case when x.kol_prop=3
		then x.plan_s-x.fact
		else 0
		end as z3
, case when x.kol_prop>3
		then x.plan_s-x.fact
		else 0
		end as z4
from 
(select 
i.merchant_id
, i.contract_number
, i.qu_inst * i.inst as r
, i.qu_inst as q_c -- 'total number of payments under the contract'
, DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30)) as d_p
, i.inst*(case when DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30)) >= i.qu_inst 
	then i.qu_inst
	else DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30))+1
end) as plan_s--'The amount of monthly installments that must be paid on the last day of the month. months'
, sum(p.payment) as fact--'Amount of payments, actual'
, i.qu_inst * i.inst - i.inst*(case when DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30)) >= i.qu_inst 
	then i.qu_inst
	else DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30))+1
end) as ost_r -- 'Installment balance excluding debt'
, z.q_propusk as kol_prop
from installment_plan i 
left join payments p on i.contract_number=p.contract_number and i.merchant_id=p.merchant_id 
left join (select 
d.merchant_id
, d.contract_number
, max (d.propusk_pl) as q_propusk
from
(select p.merchant_id
, p.contract_number
, p.date_payment
, DATEFROMPARTS(year (p.date_payment),MONTH (p.date_payment), 1) as mes_pl
, dense_rank () over (partition by p.merchant_id, p.contract_number order by DATEFROMPARTS(year (p.date_payment),MONTH (p.date_payment), 1)) as rank
, i.date_purch
, DATEDIFF(mm, i.date_purch, p.date_payment) +1  as pp
, DATEDIFF(mm, i.date_purch, p.date_payment) +1 - dense_rank () over (partition by p.merchant_id, p.contract_number order by DATEFROMPARTS(year (p.date_payment),MONTH (p.date_payment), 1)) as propusk_pl
from payments p 
 join installment_plan i on i.contract_number=p.contract_number and i.merchant_id=p.merchant_id ) d

group by d.merchant_id, d.contract_number) z on i.contract_number=z.contract_number and i.merchant_id=z.merchant_id
group by i.merchant_id, i.contract_number, i.date_purch, i.qu_inst, i.inst, p.merchant_id, p.contract_number, z.q_propusk ) x 

) y

group by y.pr, y.nz
order by y.pr, y.nz */ -- REPORT 2 Summary debt data for all installment contracts (the end) 


