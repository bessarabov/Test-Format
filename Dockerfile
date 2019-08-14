FROM perl:5.30.0

COPY lib/ /app/lib/
COPY t/ /app/t/

WORKDIR /app/
