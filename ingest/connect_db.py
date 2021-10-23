import psycopg2
CONNECTION = "postgres://root:password@localhost:5432/quantx"
conn = psycopg2.connect(CONNECTION)
cursor = conn.cursor()
for id in range(1, 4, 1):
    data = (id,)
    # create random data
    simulate_query = """SELECT generate_series(now() - interval '24 hour', now(), interval '5 minute') AS time,
                               %s as sensor_id,
                               random()*100 AS temperature,
                               random() AS cpu
                            """
    cursor.execute(simulate_query, data)
    values = cursor.fetchall()
    print(values[0])