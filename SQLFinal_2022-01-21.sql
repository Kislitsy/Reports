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



declare @c_id int -- ���������� ��� ������ ��������� ���������
declare @m_id tinyint -- ����������� ��� �������������� ��������

set @c_id=227
set @m_id=67


-----------����� 1.1 - ������, ���������� ������ � ��������� ��������� -------------

/*select i.merchant_id as '������������� ��������'
, i.contract_number as '����� ��������� ���������'
, m.merchant_name as '�������� ��������'
, c.client_name as '��� �������'
, b.Brand_name as '�������� ������' 
, p.phone_name as '�������� ��������'
, cl.color_name as '����'
, i.qu_inst as '���������� ������� �� �������� ��������� ���������' 
, i.inst as '������ ������ ������������ ������ (���.) �� �������� ��������� ���������' 
, convert (nvarchar, i.date_purch, 104) as '���� ������� (���� ������ ������� ������ �� ���������)' 
, case when DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30)) >= i.qu_inst 
	then i.qu_inst
	else DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30))+1
end
as '���������� ����������� �������, ������� ������ ���� �������� �� ��������� ���� ��������� ������' 
, i.inst*(case when DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30)) >= i.qu_inst 
	then i.qu_inst
	else DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30))+1
end) as '����� (���.) ����������� �������, ������� ������ ���� �������� �� ��������� ���� ��������� ������'
from installment_plan i 
join merchants m on i.merchant_id = m.merchant_id 
join clients c on i.client_id=c.client_id
join phones p on p.phone_id=i.phone_id
join brands b on b.brand_id=p.brand_id
join colors cl on cl.color_id=i.color_id
where i.merchant_id=@m_id and i.contract_number=@c_id */--  ����� 1.1 - ������, ���������� ������ � ��������� ��������� (����� ����)





--------------------����� 1.2 - ������, ���������� ������ � �������� �� ��������� ���������---------------
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

	select s.m_id as '������������� ��������'
	, s.c_id as '����� ��������� ���������'
	, s.year_p as '��� ������ ������ �� �������� ���������'
	, s.month_p as '����� ������ ������ �� �������� ���������'
	, s.amount as '������ ������������ ������ (���.) �� �������� ��������� ���������'
	, isnull(convert (nvarchar,p.date_payment, 104),'') as '���� ������� �������'
	, isnull (p.payment,0) as '���������� �������� �����'
	
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
	select s.m_id as '������������� ��������'
	, s.c_id as '����� ��������� ���������'
	, s.year_p as '��� ������ ������ �� �������� ���������'
	, s.month_p as '����� ������ ������ �� �������� ���������'
	, s.amount  as '������ ������������ ������ (���.) �� �������� ��������� ���������'
	, isnull(convert (nvarchar,p.date_payment, 104),'') as '���� ������� �������'
	, isnull (p.payment,0) as '���������� �������� �����'
	from @scedule_payment s
	left join payments p on s.c_id=p.contract_number and s.m_id=p.merchant_id and s.year_p=year(p.date_payment) and s.month_p=month(p.date_payment)
	left join installment_plan i on s.c_id=i.contract_number and s.m_id=i.merchant_id
	where eomonth (DATEFROMPARTS(s.year_p,s.month_p,01)) <  DATEFROMPARTS(2020,05,01)
	order by s.month_p
end  */ --  ����� 1.2 - ������, ���������� ������ � �������� �� ��������� ��������� (����� ����)



-----------����� 1.3 - ������, ���������� �������� ������ � �������� �� ��������� ���������------------

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
							as '����� (���.) ����������� �������, ������� ������ ���� �������� �� ��������� ���� ��������� ������'
					from installment_plan i 
					where i.merchant_id=@m_id and i.contract_number=@c_id) - @s_payment

insert into @contract_payment (m_id, c_id, c_payment, s_payment, o_total, z_payment) values (@m_id, @c_id, @c_payment, @s_payment, @o_total, @z_payment)
select c.m_id as '������������� ��������'
, c.c_id as '����� ��������� ���������'
, c.c_payment as '����� (���.) ����������� �������, ������� ������ ���� �������� (�����)'
, c.s_payment as '���������� �������� �����'
, c.o_total as '������� �� ��������� ��������� �����'
, z_payment as '������������� ��-�� �������� ��� �������� ������.������' 
from @contract_payment c */ --  ����� 1.3 - ������, ���������� �������� ������ � �������� �� ��������� ��������� (����� ����)





---------------����� 2 �������� ������ � ������������� �� ���� ���������� ���������  ------------------
/*select 
y.pr as '������ ���������'
, y.nz as '������� �������������'
, sum (y.sr) as '����� ���������'
, sum (y.spl) as '�����, ���. ������ ���� �����. �� ����. �� ����� ���. ���.'
, sum (y.fact) as '�����, ������� �������� �� ����. �� ����� ���.���.'
, count (y.sr) as '���-�� ��������'
, sum (y.spl)- sum (y.fact) as '�������������'
, sum (y.ost_rassr) as '������� �� ��������� ��� ����� ������-��'
, sum (y.pr0) as '���������� ��������, ������� ���������� 0 ����������� ��������'
, sum (y.pr1) as '���������� ��������, ������� ���������� 1 ����������� �����'
, sum (y.pr2) as '���������� ��������, ������� ���������� 2 ����������� �������'
, sum (y.pr3) as '���������� ��������, ������� ���������� 3 ����������� �������'
, sum (y.pr4) as '���������� ��������, ������� ���������� 4 � ����� ����������� �������'
, sum (y.z0) as '����� ������������� � ��������, ������� ���������� 0 ����������� ��������'
, sum (y.z1) as '����� ������������� � ��������, ������� ���������� 1 ����������� �����'
, sum (y.z2) as '����� ������������� � ��������, ������� ���������� 2 ����������� �������'
, sum (y.z3) as '����� ������������� � ��������, ������� ���������� 3 ����������� �������'
, sum (y.z4) as '����� ������������� � ��������, ������� ���������� 4 � ����� ����������� �������'

from 
(select 
case when x.d_p  >= x.q_c
	then '��������'
	else '�� ��������' 
	end as pr -- '������ ���������'
, case when (x.fact<x.plan_s)
		then '���� �������������'
		else '��� �������������'
	end as 	nz -- '������� �������������'
, x.r as sr --	'����� ���������'
, x.plan_s as 	spl -- '�����, ���. ������ ���� �������� �� ��������� �� ����� ��������� ������'
, x.fact as fact --'����� ��������, ����'
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
, i.qu_inst as q_c -- '���-�� ������. �� ��������� �����'
, DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30)) as d_p
, i.inst*(case when DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30)) >= i.qu_inst 
	then i.qu_inst
	else DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30))+1
end) as plan_s--'����� ������. �������, ���. ������ ���� �����. �� ����. ���� ���. ���.'
, sum(p.payment) as fact--'����� ��������, ����'
, i.qu_inst * i.inst - i.inst*(case when DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30)) >= i.qu_inst 
	then i.qu_inst
	else DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30))+1
end) as ost_r -- '������� �� ��������� ��� ����� �������������'
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
order by y.pr, y.nz */ -- ����� 2. �������� ������ � ������������� �� ���� ���������� ��������� 


