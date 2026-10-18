BEGIN;
SET LOCAL search_path TO medical, public;
CREATE TEMP TABLE test_results (label text PRIMARY KEY);
CREATE FUNCTION pg_temp.expect_error(label text, command text, expected_state text,
                                     expected_constraint text) RETURNS void
LANGUAGE plpgsql AS $$
DECLARE actual_state text; actual_constraint text;
BEGIN
    BEGIN
        EXECUTE command;
    EXCEPTION WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS actual_state = RETURNED_SQLSTATE,
                                actual_constraint = CONSTRAINT_NAME;
        IF actual_state <> expected_state OR
           (expected_constraint <> '' AND actual_constraint IS DISTINCT FROM expected_constraint) THEN
            RAISE EXCEPTION '%: ожидалось % / %, получено % / %',
                label, expected_state, expected_constraint, actual_state, actual_constraint;
        END IF;
        INSERT INTO test_results VALUES (label);
        RAISE NOTICE '%', label;
        RETURN;
    END;
    RAISE EXCEPTION 'Ожидалась ошибка: %', label;
END;
$$;

SELECT pg_temp.expect_error('Повтор номера карты',
    $sql$INSERT INTO patients (medical_record_no, full_name, birth_date, sex) VALUES ('P-000001', 'Тест', '2000-01-01', 'M')$sql$, '23505', 'uq_patients_record');

SELECT pg_temp.expect_error('Повтор табельного номера',
    $sql$INSERT INTO doctors (personnel_no, full_name, specialty_id) VALUES ('D-001', 'Тест', 1)$sql$, '23505', 'uq_doctors_personnel');

SELECT pg_temp.expect_error('Обязательное ФИО',
    $sql$UPDATE patients SET full_name = NULL WHERE patient_id = 1$sql$, '23502', '');

SELECT pg_temp.expect_error('Некорректный пол',
    $sql$UPDATE patients SET sex = 'X' WHERE patient_id = 1$sql$, '23514', 'ck_patients_sex');

SELECT pg_temp.expect_error('Некорректный телефон',
    $sql$UPDATE patients SET phone = '123' WHERE patient_id = 1$sql$, '23514', 'ck_patients_phone');

SELECT pg_temp.expect_error('Некорректная дата рождения',
    $sql$UPDATE patients SET birth_date = '1899-12-31' WHERE patient_id = 1$sql$, '23514', 'ck_patients_birth');

SELECT pg_temp.expect_error('Окончание раньше начала',
    $sql$UPDATE appointments SET ends_at = starts_at - INTERVAL '1 minute' WHERE appointment_id = 1$sql$, '23514', 'ck_appointments_time');

SELECT pg_temp.expect_error('Недопустимый статус',
    $sql$UPDATE appointments SET status = 'unknown' WHERE appointment_id = 1$sql$, '23514', 'ck_appointments_status');

SELECT pg_temp.expect_error('Несуществующий пациент',
    $sql$UPDATE appointments SET patient_id = -1 WHERE appointment_id = 1$sql$, '23503', 'fk_appointments_patient');

SELECT pg_temp.expect_error('Несуществующий врач',
    $sql$UPDATE appointments SET doctor_id = -1 WHERE appointment_id = 1$sql$, '23503', 'fk_appointments_doctor');

SELECT pg_temp.expect_error('Несуществующая специальность',
    $sql$UPDATE doctors SET specialty_id = -1 WHERE doctor_id = 1$sql$, '23503', 'fk_doctors_specialty');

SELECT pg_temp.expect_error('Повтор времени у врача',
    $sql$INSERT INTO appointments (patient_id, doctor_id, starts_at, ends_at, complaint) VALUES (3, 1, '2026-10-12 09:00+03', '2026-10-12 09:30+03', 'Тест')$sql$, '23505', 'uq_appointments_doctor_start');

SELECT pg_temp.expect_error('Повтор времени у пациента',
    $sql$INSERT INTO appointments (patient_id, doctor_id, starts_at, ends_at, complaint) VALUES (1, 3, '2026-10-12 09:00+03', '2026-10-12 09:30+03', 'Тест')$sql$, '23505', 'uq_appointments_patient_start');

SELECT pg_temp.expect_error('Повтор диагноза приёма',
    $sql$INSERT INTO appointment_diagnoses VALUES (1, 1, 'Повтор')$sql$, '23505', 'pk_appointment_diagnoses');

SELECT pg_temp.expect_error('Несуществующий диагноз',
    $sql$INSERT INTO appointment_diagnoses VALUES (1, -1, 'Тест')$sql$, '23503', 'fk_ad_diagnosis');

SELECT pg_temp.expect_error('Несуществующий приём',
    $sql$INSERT INTO appointment_diagnoses VALUES (-1, 1, 'Тест')$sql$, '23503', 'fk_ad_appointment');

SELECT pg_temp.expect_error('Пустая заметка',
    $sql$UPDATE appointment_diagnoses SET clinical_note = ' ' WHERE appointment_id = 1 AND diagnosis_id = 1$sql$, '23514', 'ck_ad_note');

SELECT pg_temp.expect_error('Удаление пациента с историей',
    $sql$DELETE FROM patients WHERE patient_id = 1$sql$, '23503', 'fk_appointments_patient');

SELECT pg_temp.expect_error('Удаление врача с приёмами',
    $sql$DELETE FROM doctors WHERE doctor_id = 1$sql$, '23503', 'fk_appointments_doctor');

SELECT pg_temp.expect_error('Удаление используемой специальности',
    $sql$DELETE FROM specialties WHERE specialty_id = 1$sql$, '23503', 'fk_doctors_specialty');

SELECT pg_temp.expect_error('Удаление используемого диагноза',
    $sql$DELETE FROM diagnoses WHERE diagnosis_id = 1$sql$, '23503', 'fk_ad_diagnosis');

DO $$
BEGIN
    IF (SELECT count(*) FROM appointment_diagnoses WHERE appointment_id = 3) <> 2 THEN
        RAISE EXCEPTION 'Нужны исходные data.sql: у приёма 3 должны быть два диагноза';
    END IF;
    DELETE FROM appointments WHERE appointment_id = 3;
    IF EXISTS (SELECT FROM appointment_diagnoses WHERE appointment_id = 3) THEN
        RAISE EXCEPTION 'ON DELETE CASCADE не сработал';
    END IF;
    IF (SELECT count(*) FROM diagnoses) <> 4 THEN
        RAISE EXCEPTION 'Каскад затронул справочник диагнозов';
    END IF;
    INSERT INTO test_results VALUES ('CASCADE удаляет только связи приёма');
    UPDATE patients SET phone = NULL WHERE patient_id = 1;
    UPDATE appointments SET ends_at = starts_at + INTERVAL '1 second' WHERE appointment_id = 1;
    INSERT INTO test_results VALUES ('Допустимые NULL и положительный интервал');
END;
$$;
DO $$
BEGIN
    IF (SELECT count(*) FROM test_results) <> 23 THEN
        RAISE EXCEPTION 'Не все 23 проверки выполнены';
    END IF;
END;
$$;
SELECT count(*) AS checks_passed FROM test_results;
ROLLBACK;
