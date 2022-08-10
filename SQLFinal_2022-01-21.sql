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



declare @c_id int -- переменная для номера контракта рассрочки
declare @m_id tinyint -- переменнная для идентификатора торговца

set @c_id=227
set @m_id=67


-----------ОТЧЕТ 1.1 - запрос, выбирающий данные о контракте рассрочки -------------

/*select i.merchant_id as 'Идентификатор торговца'
, i.contract_number as 'Номер контракта рассрочки'
, m.merchant_name as 'Название торговца'
, c.client_name as 'ФИО Клиента'
, b.Brand_name as 'Название бренда' 
, p.phone_name as 'Название телефона'
, cl.color_name as 'Цвет'
, i.qu_inst as 'Количество месяцев по условиям контракта рассрочки' 
, i.inst as 'Размер одного ежемесячного взноса (грн.) по условиям контракта рассрочки' 
, convert (nvarchar, i.date_purch, 104) as 'Дата покупки (Дата оплаты первого взноса по рассрочке)' 
, case when DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30)) >= i.qu_inst 
	then i.qu_inst
	else DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30))+1
end
as 'Количество ежемесячных взносов, которое должно быть оплачено на последний день отчетного месяца' 
, i.inst*(case when DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30)) >= i.qu_inst 
	then i.qu_inst
	else DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30))+1
end) as 'Сумма (грн.) ежемесячных взносов, которая должна быть оплачена на последний день отчетного месяца'
from installment_plan i 
join merchants m on i.merchant_id = m.merchant_id 
join clients c on i.client_id=c.client_id
join phones p on p.phone_id=i.phone_id
join brands b on b.brand_id=p.brand_id
join colors cl on cl.color_id=i.color_id
where i.merchant_id=@m_id and i.contract_number=@c_id */--  ОТЧЕТ 1.1 - запрос, выбирающий данные о контракте рассрочки (конец кода)





--------------------ОТЧЕТ 1.2 - запрос, выбирающий данные о платежах по контракту рассрочки---------------
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

	select s.m_id as 'Идентификатор торговца'
	, s.c_id as 'Номер контракта рассрочки'
	, s.year_p as 'Год оплаты взноса по условиям рассрочки'
	, s.month_p as 'Месяц оплаты взноса по условиям рассрочки'
	, s.amount as 'Размер ежемесячного взноса (грн.) по условиям контракта рассрочки'
	, isnull(convert (nvarchar,p.date_payment, 104),'') as 'Дата платежа клиента'
	, isnull (p.payment,0) as 'Оплаченная клиентом сумма'
	
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
	select s.m_id as 'Идентификатор торговца'
	, s.c_id as 'Номер контракта рассрочки'
	, s.year_p as 'Год оплаты взноса по условиям рассрочки'
	, s.month_p as 'Месяц оплаты взноса по условиям рассрочки'
	, s.amount  as 'Размер ежемесячного взноса (грн.) по условиям контракта рассрочки'
	, isnull(convert (nvarchar,p.date_payment, 104),'') as 'Дата платежа клиента'
	, isnull (p.payment,0) as 'Оплаченная клиентом сумма'
	from @scedule_payment s
	left join payments p on s.c_id=p.contract_number and s.m_id=p.merchant_id and s.year_p=year(p.date_payment) and s.month_p=month(p.date_payment)
	left join installment_plan i on s.c_id=i.contract_number and s.m_id=i.merchant_id
	where eomonth (DATEFROMPARTS(s.year_p,s.month_p,01)) <  DATEFROMPARTS(2020,05,01)
	order by s.month_p
end  */ --  ОТЧЕТ 1.2 - запрос, выбирающий данные о платежах по контракту рассрочки (конец кода)



-----------ОТЧЕТ 1.3 - запрос, выбирающий итоговые данные о платежах по контракту рассрочки------------

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
							as 'Сумма (грн.) ежемесячных взносов, которая должна быть оплачена на последний день отчетного месяца'
					from installment_plan i 
					where i.merchant_id=@m_id and i.contract_number=@c_id) - @s_payment

insert into @contract_payment (m_id, c_id, c_payment, s_payment, o_total, z_payment) values (@m_id, @c_id, @c_payment, @s_payment, @o_total, @z_payment)
select c.m_id as 'Идентификатор торговца'
, c.c_id as 'Номер контракта рассрочки'
, c.c_payment as 'Сумма (грн.) ежемесячных взносов, которая должна быть оплачена (всего)'
, c.s_payment as 'Оплаченная клиентом сумма'
, c.o_total as 'Остаток по контракту рассрочки всего'
, z_payment as 'Задолженность из-за недоплат или пропуска ежемес.взноса' 
from @contract_payment c */ --  ОТЧЕТ 1.3 - запрос, выбирающий итоговые данные о платежах по контракту рассрочки (конец кода)





---------------ОТЧЕТ 2 Итоговые данные о задолженности по всем контрактам рассрочки  ------------------
/*select 
y.pr as 'Период рассрочки'
, y.nz as 'Наличие задолженности'
, sum (y.sr) as 'Сумма рассрочки'
, sum (y.spl) as 'Сумма, кот. должна быть оплач. по сост. на конец отч. мес.'
, sum (y.fact) as 'Сумма, которая оплачена по сост. на конец отч.мес.'
, count (y.sr) as 'кол-во клиентов'
, sum (y.spl)- sum (y.fact) as 'Задолженность'
, sum (y.ost_rassr) as 'Остаток по рассрочке без учёта задолж-ти'
, sum (y.pr0) as 'Количество клиентов, которые просрочили 0 ежемесячных платежей'
, sum (y.pr1) as 'Количество клиентов, которые просрочили 1 ежемесячный платёж'
, sum (y.pr2) as 'Количество клиентов, которые просрочили 2 ежемесячных платежа'
, sum (y.pr3) as 'Количество клиентов, которые просрочили 3 ежемесячных платежа'
, sum (y.pr4) as 'Количество клиентов, которые просрочили 4 и более ежемесячных платежа'
, sum (y.z0) as 'Сумма задолженности у клиентов, которые просрочили 0 ежемесячных платежей'
, sum (y.z1) as 'Сумма задолженности у клиентов, которые просрочили 1 ежемесячный платёж'
, sum (y.z2) as 'Сумма задолженности у клиентов, которые просрочили 2 ежемесячных платежа'
, sum (y.z3) as 'Сумма задолженности у клиентов, которые просрочили 3 ежемесячных платежа'
, sum (y.z4) as 'Сумма задолженности у клиентов, которые просрочили 4 и более ежемесячных платежа'

from 
(select 
case when x.d_p  >= x.q_c
	then 'Закончен'
	else 'Не закончен' 
	end as pr -- 'Период рассрочки'
, case when (x.fact<x.plan_s)
		then 'Есть задолженность'
		else 'Нет задолженности'
	end as 	nz -- 'Наличие задолженности'
, x.r as sr --	'Сумма рассрочки'
, x.plan_s as 	spl -- 'Сумма, кот. должна быть оплачена по состоянию на конец отчетного месяца'
, x.fact as fact --'Сумма платежей, факт'
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
, i.qu_inst as q_c -- 'кол-во платеж. по контракту всего'
, DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30)) as d_p
, i.inst*(case when DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30)) >= i.qu_inst 
	then i.qu_inst
	else DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30))+1
end) as plan_s--'Сумма ежемес. взносов, кот. должна быть оплач. на посл. день отч. мес.'
, sum(p.payment) as fact--'Сумма платежей, факт'
, i.qu_inst * i.inst - i.inst*(case when DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30)) >= i.qu_inst 
	then i.qu_inst
	else DATEDIFF (mm,i.date_purch,datefromparts(2020,04,30))+1
end) as ost_r -- 'Остаток по рассрочке без учета задолженности'
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
order by y.pr, y.nz */ -- ОТЧЕТ 2. Итоговые данные о задолженности по всем контрактам рассрочки 


