BEGIN;
CREATE SCHEMA medical;
SET LOCAL search_path TO medical, public;

CREATE TABLE specialties (
    specialty_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name text NOT NULL,
    CONSTRAINT uq_specialties_name UNIQUE (name),
    CONSTRAINT ck_specialties_name CHECK (btrim(name) <> '')
);

CREATE TABLE patients (
    patient_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    medical_record_no varchar(20) NOT NULL,
    full_name text NOT NULL,
    birth_date date NOT NULL,
    sex char(1) NOT NULL,
    phone varchar(16),
    CONSTRAINT uq_patients_record UNIQUE (medical_record_no),
    CONSTRAINT ck_patients_record CHECK (medical_record_no ~ '^P-[0-9]{6}$'),
    CONSTRAINT ck_patients_name CHECK (btrim(full_name) <> ''),
    CONSTRAINT ck_patients_birth CHECK (birth_date >= DATE '1900-01-01' AND isfinite(birth_date)),
    CONSTRAINT ck_patients_sex CHECK (sex IN ('M', 'F')),
    CONSTRAINT ck_patients_phone CHECK (phone ~ '^\+[1-9][0-9]{7,14}$')
);

CREATE TABLE doctors (
    doctor_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    personnel_no varchar(20) NOT NULL,
    full_name text NOT NULL,
    specialty_id bigint NOT NULL,
    CONSTRAINT uq_doctors_personnel UNIQUE (personnel_no),
    CONSTRAINT ck_doctors_personnel CHECK (btrim(personnel_no) <> ''),
    CONSTRAINT ck_doctors_name CHECK (btrim(full_name) <> ''),
    CONSTRAINT fk_doctors_specialty FOREIGN KEY (specialty_id)
        REFERENCES specialties (specialty_id) ON DELETE RESTRICT
);

CREATE TABLE diagnoses (
    diagnosis_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code varchar(12) NOT NULL,
    name text NOT NULL,
    CONSTRAINT uq_diagnoses_code UNIQUE (code),
    CONSTRAINT ck_diagnoses_code CHECK (btrim(code) <> ''),
    CONSTRAINT ck_diagnoses_name CHECK (btrim(name) <> '')
);

CREATE TABLE appointments (
    appointment_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    patient_id bigint NOT NULL,
    doctor_id bigint NOT NULL,
    starts_at timestamptz NOT NULL,
    ends_at timestamptz NOT NULL,
    status varchar(12) NOT NULL DEFAULT 'scheduled',
    complaint text NOT NULL,
    CONSTRAINT fk_appointments_patient FOREIGN KEY (patient_id)
        REFERENCES patients (patient_id) ON DELETE RESTRICT,
    CONSTRAINT fk_appointments_doctor FOREIGN KEY (doctor_id)
        REFERENCES doctors (doctor_id) ON DELETE RESTRICT,
    CONSTRAINT uq_appointments_doctor_start UNIQUE (doctor_id, starts_at),
    CONSTRAINT uq_appointments_patient_start UNIQUE (patient_id, starts_at),
    CONSTRAINT ck_appointments_time CHECK (isfinite(starts_at) AND isfinite(ends_at) AND ends_at > starts_at),
    CONSTRAINT ck_appointments_status CHECK (status IN ('scheduled', 'completed', 'cancelled')),
    CONSTRAINT ck_appointments_complaint CHECK (btrim(complaint) <> '')
);

CREATE TABLE appointment_diagnoses (
    appointment_id bigint NOT NULL,
    diagnosis_id bigint NOT NULL,
    clinical_note text NOT NULL,
    CONSTRAINT pk_appointment_diagnoses PRIMARY KEY (appointment_id, diagnosis_id),
    CONSTRAINT fk_ad_appointment FOREIGN KEY (appointment_id)
        REFERENCES appointments (appointment_id) ON DELETE CASCADE,
    CONSTRAINT fk_ad_diagnosis FOREIGN KEY (diagnosis_id)
        REFERENCES diagnoses (diagnosis_id) ON DELETE RESTRICT,
    CONSTRAINT ck_ad_note CHECK (btrim(clinical_note) <> '')
);

CREATE INDEX ix_doctors_specialty ON doctors (specialty_id);
CREATE INDEX ix_ad_diagnosis ON appointment_diagnoses (diagnosis_id);
COMMIT;
