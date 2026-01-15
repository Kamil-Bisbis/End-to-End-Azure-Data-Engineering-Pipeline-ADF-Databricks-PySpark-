CREATE LOGIN de_pipeline_user WITH PASSWORD = '<STRONG_PASSWORD>';
GO

CREATE USER de_pipeline_user FOR LOGIN de_pipeline_user;
GO