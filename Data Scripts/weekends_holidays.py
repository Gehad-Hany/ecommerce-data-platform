import pandas as pd

def generate_brazil_calendar(years):
    fixed_holidays = {
        "01-01": "New Year's Day",
        "04-21": "Tiradentes Day",
        "05-01": "Labor Day",
        "09-07": "Independence Day",
        "10-12": "Our Lady of Aparecida",
        "11-02": "All Souls' Day",
        "11-15": "Republic Proclamation Day",
        "12-25": "Christmas Day"
    }
    
    easter_dates = {
        2016: pd.Timestamp("2016-03-27"),
        2017: pd.Timestamp("2017-04-16"),
        2018: pd.Timestamp("2018-04-01")
    }
    
    data = []
    for year in years:
        easter = easter_dates[year]
        
        movable = {
            (easter - pd.Timedelta(days=48)).strftime('%m-%d'): "Carnival",
            (easter - pd.Timedelta(days=47)).strftime('%m-%d'): "Carnival",
            (easter - pd.Timedelta(days=2)).strftime('%m-%d'): "Good Friday",
            (easter).strftime('%m-%d'): "Easter Sunday",
            (easter + pd.Timedelta(days=60)).strftime('%m-%d'): "Corpus Christi"
        }
        
        year_holidays = {**fixed_holidays, **movable}
        
        date_range = pd.date_range(f"{year}-01-01", f"{year}-12-31")
        
        for dt in date_range:
            m_d = dt.strftime('%m-%d')
            is_holiday = m_d in year_holidays
            is_weekend = dt.weekday() >= 5 
            
            if is_holiday or is_weekend:
                # If a holiday is on a weekend, the holiday name is used
                event_name = year_holidays[m_d] if is_holiday else dt.day_name()
                event_type = "Public Holiday" if is_holiday else "Weekend"
                
                data.append({
                    "year": year,
                    "date": dt.strftime('%Y-%m-%d'),
                    "name": event_name,
                    "type": event_type,
                    "country": "BR"
                })
                
    return pd.DataFrame(data)

years_to_process = [2016, 2017, 2018]
df = generate_brazil_calendar(years_to_process)

df.to_csv(r"E:\ITI Graduation project\Data\brazil_holidays_weekends_2016_2018.csv", index=False)
print("File 'brazil_holidays_weekends_2016_2018.csv' has been created.")