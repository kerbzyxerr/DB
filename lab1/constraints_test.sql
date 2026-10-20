INSERT INTO medical.patients (medical_record_no, full_name, birth_date, sex)
VALUES ('P-000001', 'Иванов Иван Иванович', '2000-01-01', 'M');

INSERT INTO medical.patients (medical_record_no, full_name, birth_date, sex)
VALUES ('P-000005', NULL, '2000-01-01', 'M');

INSERT INTO medical.patients (medical_record_no, full_name, birth_date, sex)
VALUES ('P-000006', 'Иванов Иван Иванович', '2000-01-01', 'X');

INSERT INTO medical.patients (medical_record_no, full_name, birth_date, sex, phone)
VALUES ('P-000007', 'Иванов Иван Иванович', '2000-01-01', 'M', '123');

INSERT INTO medical.doctors (personnel_no, full_name, specialty_id)
VALUES ('D-005', 'Петров Пётр Петрович', -1);

INSERT INTO medical.appointments (patient_id, doctor_id, starts_at, ends_at, complaint)
VALUES (1, 1, '2026-10-21 10:00+03', '2026-10-21 09:30+03', 'Головная боль');

INSERT INTO medical.appointments (patient_id, doctor_id, starts_at, ends_at, complaint)
VALUES (3, 1, '2026-10-12 09:00+03', '2026-10-12 09:30+03', 'Головная боль');

INSERT INTO medical.appointment_diagnoses (appointment_id, diagnosis_id, clinical_note)
VALUES (1, 1, 'Повторный диагноз');
