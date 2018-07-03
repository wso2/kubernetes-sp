-- 
-- Copyright 2018 WSO2 Inc. (http://wso2.org)
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--     http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

DROP DATABASE IF EXISTS SP_MGT_DB;
DROP DATABASE IF EXISTS SP_WORKER_STATE_DB;

CREATE DATABASE SP_MGT_DB;
CREATE DATABASE SP_WORKER_STATE_DB;
CREATE DATABASE cepDB;
CREATE DATABASE spDB;

CREATE USER IF NOT EXISTS 'wso2carbon'@'%' IDENTIFIED BY 'wso2carbon';
GRANT ALL ON SP_MGT_DB.* TO 'wso2carbon'@'%' IDENTIFIED BY 'wso2carbon';
GRANT ALL ON SP_WORKER_STATE_DB.* TO 'wso2carbon'@'%' IDENTIFIED BY 'wso2carbon';
GRANT ALL ON cepDB.* TO 'wso2carbon'@'%' IDENTIFIED BY 'wso2carbon';
GRANT ALL ON spDB.* TO 'wso2carbon'@'%' IDENTIFIED BY 'wso2carbon';

