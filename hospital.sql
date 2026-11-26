-- 1. Tabla Pacientes (Sin dependencias)
CREATE TABLE pacientes (
    id_paciente bigint PRIMARY KEY,
    nombre text NOT NULL,
    apellidos text NOT NULL,
    fecha_nacimiento date NOT NULL,
    sexo text NOT NULL CHECK (sexo IN ('M', 'F')),
    telefono text,
    direccion text,
    tipo_sangre text,
    fecha_registro date DEFAULT current_timestamp
);

-- 2. Tabla Especialidades (Sin dependencias)
CREATE TABLE especialidades (
    id_especialidad bigint PRIMARY KEY,
    nombre_especialidad text NOT NULL,
    descripcion text
);

-- 3. Tabla Medicamentos (Sin dependencias)
CREATE TABLE medicamentos (
    id_medicamento bigint PRIMARY KEY,
    nombre_medicamento text NOT NULL,
    descripcion text,
    presentacion text,
    existencia integer NOT NULL CHECK (existencia >= 0),
    precio numeric(10,2) NOT NULL CHECK (precio >= 0),
    fecha_caducidad date NOT NULL
);

-- 4. Tabla Medicos (Depende de especialidades) - Nota: "aprellidos" tal como en tu documento
CREATE TABLE medicos (
    id_medico bigint PRIMARY KEY,
    nombre text NOT NULL,
    aprellidos text NOT NULL,
    cedula_profesional text UNIQUE NOT NULL,
    id_especialidad bigint REFERENCES especialidades(id_especialidad) ON DELETE RESTRICT,
    telefono text,
    correo text,
    estatus text NOT NULL CHECK (estatus IN ('Activo', 'Inactivo'))
);

-- 5. Tabla Consultas (Depende de pacientes y medicos)
CREATE TABLE consultas (
    id_consulta bigint PRIMARY KEY,
    id_paciente bigint REFERENCES pacientes(id_paciente) ON DELETE RESTRICT,
    id_medico bigint REFERENCES medicos(id_medico) ON DELETE RESTRICT,
    fecha_consulta date NOT NULL,
    hora_consulta time NOT NULL,
    motivo_consulta text,
    diagnostico text,
    costo_consulta numeric(10,2) NOT NULL CHECK (costo_consulta >= 0),
    estatus text NOT NULL CHECK (estatus IN ('Completada', 'Pendiente', 'Cancelada'))
);

-- 6. Tabla Tratamientos (Depende de consultas y medicamentos) - Nota: "calve" corregido a REFERENCES
CREATE TABLE tratamientos (
    id_tratamiento bigint PRIMARY KEY,
    id_consulta bigint REFERENCES consultas(id_consulta) ON DELETE CASCADE,
    id_medicamento bigint REFERENCES medicamentos(id_medicamento) ON DELETE RESTRICT,
    dosis text NOT NULL,
    frecuencia text NOT NULL,
    duracion_dias integer NOT NULL CHECK (duracion_dias > 0),
    cantidad integer NOT NULL CHECK (cantidad > 0),
    indicaciones text
);


-- 1. Habilitar la extensión postgres_fdw
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- 2. Crear los tres servidores externos
CREATE SERVER servidor_ixtapaluca
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'aws-1-us-east-1.pooler.supabase.com', port '5432', dbname 'postgres');

CREATE SERVER servidor_valle_chalco
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'aws-1-us-east-2.pooler.supabase.com', port '5432', dbname 'postgres');

CREATE SERVER servidor_amecameca
    FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host 'aws-1-us-west-2.pooler.supabase.com', port '5432', dbname 'postgres');

-- 3. Mapear tu usuario local 'postgres' con los roles creados en Supabase
-- IMPORTANTE: Con el Pooler de Supabase, el user debe llevar el formato: rol.reference_id
CREATE USER MAPPING FOR postgres
    SERVER servidor_ixtapaluca
    OPTIONS (user 'fdw_ixtapaluca.gywaonmlqcbeyytwsfpw', password '12345!');

CREATE USER MAPPING FOR postgres
    SERVER servidor_valle_chalco
     OPTIONS (user 'fdw_valle_chalco.gwzjlwyheenillxlsxen', password '202326066_Nicol');

CREATE USER MAPPING FOR postgres
    SERVER servidor_amecameca
    OPTIONS (user 'fdw_amecameca.rbqlubvcerlksexibjcj', password '12345');

-- 4. Crear los esquemas correspondientes a cada hospital
CREATE SCHEMA esquema_ixtapaluca;
CREATE SCHEMA esquema_valle_chalco;
CREATE SCHEMA esquema_amecameca;

-- 5. Importar las 6 tablas de cada servidor remoto
IMPORT FOREIGN SCHEMA public
    LIMIT TO (pacientes, especialidades, medicos, consultas, medicamentos, tratamientos)
    FROM SERVER servidor_ixtapaluca
    INTO esquema_ixtapaluca;

IMPORT FOREIGN SCHEMA public
    LIMIT TO (pacientes, especialidades, medicos, consultas, medicamentos, tratamientos)
    FROM SERVER servidor_valle_chalco
    INTO esquema_valle_chalco;

IMPORT FOREIGN SCHEMA public
    LIMIT TO (pacientes, especialidades, medicos, consultas, medicamentos, tratamientos)
    FROM SERVER servidor_amecameca
    INTO esquema_amecameca;
