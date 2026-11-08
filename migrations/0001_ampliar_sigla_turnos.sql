-- V1.0.7: permite siglas de turnos com ate quatro caracteres.
-- Preserva os registros, indices, chaves e restricoes existentes.
ALTER TABLE public.turnos
    ALTER COLUMN turnossigla TYPE varchar(4);
