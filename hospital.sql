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